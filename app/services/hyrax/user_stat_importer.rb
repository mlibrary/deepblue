# frozen_string_literal: true
# Reviewed: hyrax4 # may need revisit

# monkey override

module Deepblue

  require_relative '../../tasks/deepblue/abstract_task'

  class UserStatImporter < AbstractTask

    attr_accessor :delay_secs, :echo_to_stdout, :logging, :number_of_retries, :test
    # attr_accessor :hostname, :hostnames

    def initialize( options: {} )
      super( options: options )
      # @verbose = task_options_value( key: 'verbose', default_value: false )
      # ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
      # @hostnames = task_options_value( key: 'hostnames', default_value: [] )
      # @hostname = Rails.configuration.hostname
      # return unless @hostnames.include? @hostname
      @test = task_options_value( key: 'test', default_value: true )
      @echo_to_stdout = task_options_value( key: 'echo_to_stdout', default_value: false )
      @logging = task_options_value( key: 'logging', default_value: false )
      @number_of_retries = task_options_value( key: 'number_of_retries', default_value: nil )
      @delay_secs = task_options_value( key: 'delay_secs', default_value: nil )
    end

    def run
      importer = Hyrax::UserStatImporter.new( echo_to_stdout: echo_to_stdout,
                                              verbose: verbose,
                                              delay_secs: delay_secs,
                                              logging: logging,
                                              number_of_retries: number_of_retries,
                                              test: test )
      importer.import
    end

  end

end

module Hyrax

  require 'retriable'

  # Cache work view, file view & file download stats for all users
  # this is called by 'rake hyrax:stats:user_stats'
  class UserStatImporter

    mattr_accessor :user_stat_importer_debug_verbose, default: Rails.configuration.user_stat_importer_debug_verbose

    UserRecord = Struct.new("UserRecord", :id, :user_key, :last_stats_update)

    def initialize(options = {})
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if user_stat_importer_debug_verbose
      if options[:echo_to_stdout]
        stdout_logger = Logger.new(STDOUT)
        stdout_logger.level = Logger::INFO
        Rails.logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
      end
      @verbose = options[:verbose]
      log_message("@verbose=#{@verbose}")
      @logging = options[:logging]
      log_message("@logging=#{@logging}")
      @delay_secs = options[:delay_secs].to_f
      log_message("@delay_secs=#{@delay_secs}")
      @number_of_tries = options[:number_of_retries].to_i + 1
      log_message("@number_of_tries=#{@number_of_tries}")
      @test = options[:test]
      log_message("@test=#{@test}")
      @process_works = true
      @process_files = false # TODO: reactivate
      @create_or_update_user_stats = false # TODO: reactivate
    end

    delegate :depositor_field, to: DepositSearchBuilder

    def import
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if user_stat_importer_debug_verbose
      log_message('Begin import of User stats.')

      users = sorted_users
      log_message("users.size=#{users.size}")
      users.each do |user|
        start_date = date_since_last_cache(user)
        log_message( "processing user #{user} with start_date #{start_date}" )
        # this user has already been processed today continue without delay
        next if start_date.to_date >= Time.zone.today
        stats = {}
        process_files(stats, user, start_date) if @process_files
        process_works(stats, user, start_date) if @process_works
        create_or_update_user_stats(stats, user) if @create_or_update_user_stats
      end
      log_message('User stats import complete.')
    end

    # Returns an array of users sorted by the date of their last stats update. Users that have not been recently updated
    # will be at the top of the array.
    def sorted_users
      users = []
      ::User.find_each do |user|
        users.push(UserRecord.new(user.id, user.user_key, date_since_last_cache(user)))
        return users if @test
      end
      users.sort_by(&:last_stats_update)
    end

    private

      def process_files(stats, user, start_date)
        log_message("process files user=#{user} start_date=#{start_date}")
        return if @test
        file_ids_for_user(user).each do |file_id|
          file = ::FileSet.find(file_id)
          view_stats = extract_stats_for(object: file, from: FileViewStat, start_date: start_date, user: user)
          stats = tally_results(view_stats, :views, stats) if view_stats.present?
          delay
          dl_stats = extract_stats_for(object: file, from: FileDownloadStat, start_date: start_date, user: user)
          stats = tally_results(dl_stats, :downloads, stats) if dl_stats.present?
          delay
        end
      end

      def process_works(stats, user, start_date)
        log_message("process works user=#{user} start_date=#{start_date}")
        return if @test
        work_ids_for_user(user).each do |work_id|
          log_message( "processing user #{user} work #{work_id} with start_date #{start_date}" )
          work = Hyrax::WorkRelation.new.find(work_id)
          work_stats = extract_stats_for(object: work, from: WorkViewStat, start_date: start_date, user: user)
          stats = tally_results(work_stats, :work_views, stats) if work_stats.present?
          delay
        end
      end

      def extract_stats_for(object:, from:, start_date:, user:)
        rescue_and_retry("Retried #{from} on #{user} for #{object.class} #{object.id} too many times.") { from.statistics(object, start_date, user.id) }
      end

      def delay
        sleep @delay_secs
      end

      # This method never fails. It tries multiple times and finally logs the exception
      def rescue_and_retry(fail_message)
        ::Retriable.retriable(retry_options) do
          return yield
        end
      rescue StandardError => exception
        log_message fail_message
        log_message "Last exception #{exception}"
      end

      def date_since_last_cache(user)
        last_cached_stat = UserStat.where(user_id: user.id).order(date: :asc).last

        if last_cached_stat
          last_cached_stat.date + 1.day
        else
          Hyrax.config.analytic_start_date
        end
      end

      def file_ids_for_user(user)
        ids = []
        ::FileSet.search_in_batches("#{depositor_field}:\"#{user.user_key}\"", fl: "id") do |group|
          ids.concat group.map { |doc| doc["id"] }
        end
        ids
      end

      def work_ids_for_user(user)
        ids = []
        Hyrax::WorkRelation.new.search_in_batches("#{depositor_field}:\"#{user.user_key}\"", fl: "id") do |group|
          ids.concat group.map { |doc| doc["id"] }
        end
        ids
      end

      # For each date, add the view and download counts for this file to the view & download sub-totals for that day.
      # The resulting hash will look something like this: {"2014-11-30 00:00:00 UTC" => {:views=>2, :downloads=>5},
      # "2014-12-01 00:00:00 UTC" => {:views=>4, :downloads=>4}}
      def tally_results(current_stats, stat_name, total_stats)
        current_stats.each do |stats|
          # Exclude the stats from today since it will only be a partial day's worth of data
          break if stats.date == Time.zone.today

          date_key = stats.date.to_s
          old_count = total_stats[date_key] ? total_stats[date_key].fetch(stat_name) { 0 } : 0
          new_count = old_count + stats.method(stat_name).call

          old_values = total_stats[date_key] || {}
          total_stats.store(date_key, old_values)
          total_stats[date_key].store(stat_name, new_count)
        end
        total_stats
      end

      def create_or_update_user_stats(stats, user)
        log_message("create or update user stats user=#{user}")
        return if @test
        stats.each do |date_string, data|
          date = Time.zone.parse(date_string)

          user_stat = UserStat.where(user_id: user.id, date: date).first_or_initialize(user_id: user.id, date: date)

          user_stat.file_views = data.fetch(:views, 0)
          user_stat.file_downloads = data.fetch(:downloads, 0)
          user_stat.work_views = data.fetch(:work_views, 0)
          user_stat.save!
        end
      end

      def log_message(message)
        ::Deepblue::LoggingHelper.debug message if @verbose
        # Rails.logger.info "#{self.class}: #{message}" if @logging
      end

      def retry_options
        { tries: @number_of_tries }
      end

  end

end
