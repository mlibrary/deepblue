# frozen_string_literal: true

require "abstract_rake_task_job"
require "find_and_fix_empty_file_sizes_behavior"
require "find_and_fix_ordered_members_behavior"

class FindAndFixCurationConcernFilterDate

  attr_reader :begin_date, :end_date

  def to_datetime( date, format: nil )
    return nil if date.blank?
    date = date.strip
    date = date.downcase
    if format.nil?
      case date
      when /^now$/
        return DateTime.now
      when /^now\s+([+-])\s*([0-9]+)\s+(days?|weeks?|months?|years?)$/
        plus_minus = Regexp.last_match 1
        number = Regexp.last_match 2
        number = number.to_i
        units = Regexp.last_match 3
        if '-' == plus_minus
          case units
          when 'day'
            return DateTime.now - number.day
          when 'days'
            return DateTime.now - number.days
          when 'week'
            return DateTime.now - number.week
          when 'weeks'
            return DateTime.now - number.weeks
          when 'month'
            return DateTime.now - number.month
          when 'months'
            return DateTime.now - number.months
          when 'year'
            return DateTime.now - number.year
          when 'years'
            return DateTime.now - number.years
          else
            raise RuntimeError 'Should never get here.'
          end
        else
          case units
          when 'day'
            return DateTime.now + number.day
          when 'days'
            return DateTime.now + number.days
          when 'week'
            return DateTime.now + number.week
          when 'weeks'
            return DateTime.now + number.weeks
          when 'month'
            return DateTime.now + number.month
          when 'months'
            return DateTime.now + number.months
          when 'year'
            return DateTime.now + number.year
          when 'years'
            return DateTime.now + number.years
          else
            raise RuntimeError 'Should never get here.'
          end
        end
      else
        return DateTime.parse( date ) if format.nil?
      end
    end
    rv = nil
    begin
      rv = DateTime.strptime( date, format )
    rescue ArgumentError => e
      msg_puts "ERROR: ArgumentError in FindAndFixCurationConcernFilterDate.to_datetime( #{date}, #{format} )"
      raise e
    end
    return rv
  end

  def initialize( begin_date:, end_date: )
    @begin_date = to_datetime( begin_date )
    @end_date = to_datetime( end_date )
  end

  def include?( date: )
    return false if date.nil?
    return date >= @begin if @end_date.nil?
    return date <= @end if @begin_date.nil?
    rv = date.between?( @begin_date, @end_date )
    return rv
  end

end


class FindAndFixJob < AbstractRakeTaskJob

  include FindAndFixEmptyFileSizesBehavior
  include FindAndFixOrderedMembersBehavior
  include FindAndFixOverFileSetsBehavior

  # bundle exec rake deepblue:run_job['{"job_class":"FindAndFixJob"\,"verbose":true\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0}']

  mattr_accessor :find_and_fix_job_debug_verbose
  @@find_and_fix_job_debug_verbose = false

  # queue_as :scheduler

EXAMPLE_SCHEDULER_ENTRY = <<-END_OF_EXAMPLE_SCHEDULER_ENTRY

find_and_fix_job:
# Run once a day, 15 minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
#       M H D
  cron: '15 5 * * *'
  class: FindAndFixJob
  queue: scheduler
  description: Find and fix problems
  args:
    email_results_to:
      - 'fritx@umich.edu'
    filter_date_begin: now - 7 days
    filter_date_end: now
    find_and_fix_empty_file_size: true
    find_and_fix_over_file_sets: true
    find_and_fix_all_ordered_members_containing_nils: true
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    subscription_service_id: find_and_fix_job
    verbose: true

END_OF_EXAMPLE_SCHEDULER_ENTRY

  def self.perform( *args )
    RakeTaskJob.perform_now( *args )
  end

  attr_accessor :filter_date_begin, :filter_date_end, :filter_date

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if find_and_fix_job_debug_verbose
    initialized = initialize_from_args( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "initialized=#{initialized}",
                                           "" ] if find_and_fix_job_debug_verbose
    @filter_date = nil
    @filter_date_begin = job_options_value( options, key: 'filter_date_begin', default_value: nil, verbose: verbose )
    @filter_date_end = job_options_value( options, key: 'filter_date_end', default_value: nil, verbose: verbose )
    if @filter_date_begin.present? || @filter_date_end
      @filter_date = FindAndFixCurationConcernFilterDate.new( begin_date: filter_date_begin, end_date: filter_date_end )
      job_msg_queue << "Filter dates between #{filter_date.begin_date} and #{filter_date_end}."
    end
    find_and_fix_empty_file_size = job_options_value( options,
                                                      key: 'find_and_fix_empty_file_size',
                                                      default_value: true,
                                                      verbose: verbose )
    job_msg_queue << "find_and_fix_empty_file_size=#{find_and_fix_empty_file_size}"
    find_and_fix_over_file_sets = job_options_value( options,
                                                      key: 'find_and_fix_over_file_sets',
                                                      default_value: true,
                                                      verbose: verbose )
    job_msg_queue << "find_and_fix_over_file_sets=#{find_and_fix_over_file_sets}"
    find_and_fix_all_ordered_members_containing_nils = job_options_value( options,
                                                      key: 'find_and_fix_all_ordered_members_containing_nils',
                                                      default_value: true,
                                                      verbose: verbose )
    job_msg_queue << "find_and_fix_all_ordered_members_containing_nils=#{find_and_fix_all_ordered_members_containing_nils}"
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "job_options_keys_found=#{job_options_keys_found}",
                                           "verbose=#{verbose}",
                                           "hostnames=#{hostnames}",
                                           "email_targets=#{email_targets}",
                                           "initialized=#{initialized}",
                                           "job_delay=#{job_delay}",
                                           "find_and_fix_empty_file_size=#{find_and_fix_empty_file_size}",
                                           "find_and_fix_all_ordered_members_containing_nils=#{find_and_fix_all_ordered_members_containing_nils}",
                                           "" ] if find_and_fix_job_debug_verbose
    return unless initialized
    run_job_delay
    if find_and_fix_empty_file_size
      file_set_ids_fixed = []
      find_and_fix_empty_file_sizes( filter: @filter_date,
                                     messages: job_msg_queue,
                                     ids_fixed: file_set_ids_fixed,
                                     verbose: verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "timestamp_end=#{timestamp_end}",
                                             "job_msg_queue=#{job_msg_queue}",
                                             "file_set_ids_fixed=#{file_set_ids_fixed}",
                                             "" ] if find_and_fix_job_debug_verbose
    end
    if find_and_fix_over_file_sets
      file_set_ids_fixed = []
      find_and_fix_over_file_sets( filter: @filter_date,
                                   messages: job_msg_queue,
                                   ids_fixed: file_set_ids_fixed,
                                   verbose: verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "timestamp_end=#{timestamp_end}",
                                             "job_msg_queue=#{job_msg_queue}",
                                             "file_set_ids_fixed=#{file_set_ids_fixed}",
                                             "" ] if find_and_fix_job_debug_verbose
    end
    if find_and_fix_all_ordered_members_containing_nils
      curation_concern_ids_fixed = []
      find_and_fix_all_ordered_members_containing_nils( filter: @filter_date,
                                                        messages: job_msg_queue,
                                                        ids_fixed: curation_concern_ids_fixed,
                                                        verbose: verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "job_msg_queue=#{job_msg_queue}",
                                             "curation_concern_ids_fixed=#{curation_concern_ids_fixed}",
                                             "" ] if find_and_fix_job_debug_verbose
    end
    timestamp_end = DateTime.now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_msg_queue=#{job_msg_queue}",
                                           "timestamp_end=#{timestamp_end}",
                                           "" ] if find_and_fix_job_debug_verbose
    email_results( task_name: "Find and Fix", event: 'find and fix job' )
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace[0..20].join("\n")
    email_failure( task_name: "find and fix job", exception: e, event: 'find and fix' )
    raise e
  end

  # def self.queue
  #   :default
  # end

end
