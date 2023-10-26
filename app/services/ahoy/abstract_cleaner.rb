# frozen_string_literal: true

module Ahoy

  class AbstractCleaner

    AHOY_ERA_START = DateTime.new(2021,1,1).beginning_of_day

    INC_DAY = 1.day
    INC_WEEK = 7.days

    SPAN_DAY = "day"
    SPAN_MONTH = "month"
    SPAN_WEEK = "week"

    mattr_accessor :ahoy_abstract_cleaner_debug_verbose, default: false

    attr_accessor :msg_handler, :debug_verbose, :quiet, :task, :verbose

    attr_accessor :begin_date
    attr_accessor :delete
    attr_accessor :inc
    attr_accessor :ips
    attr_accessor :report_base_filename
    attr_accessor :report_dir
    attr_accessor :report_summary
    attr_accessor :span
    attr_accessor :span_days
    attr_accessor :trim_date

    def initialize( begin_date:,
                    trim_date:,
                    delete:,
                    inc:,
                    span:,
                    span_days:,
                    msg_handler: nil,
                    quiet: false,
                    task: false,
                    verbose: false,
                    debug_verbose: ahoy_abstract_cleaner_debug_verbose )

      @verbose = verbose
      @quiet = quiet
      @debug_verbose = debug_verbose
      @task = task
      @msg_handler = msg_handler
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "" ] if debug_verbose

      @span_days = span_days

      @high_event_count = 999999  # effectively disabled
      #@high_visit_count = 9999
      @high_visit_count_per_day = 99
      #@high_visit_event_count = 999
      @high_visit_event_count_per_day = 24

      @inc = inc
      @span = span
      @delete = delete
      @begin_date = begin_date
      @trim_date = trim_date

      @ips = {}

    end

    def add_ip(visit, event_count)
      @ips ||= {}
      ip = visit.ip
      ip_info = @ips[ip];ip_info ||= { visit_ids: [], event_count: 0 }
      ip_info[:visit_ids] << visit.id
      ip_info[:event_count] = ip_info[:event_count] + event_count
      @ips[ip] = ip_info
    end

    def crawler_ip?(ip)
      return true if ip.start_with?("66.249.6")
      return true if ip.start_with?("66.249.7")
      return false
    end

    def debug_verbose
      @msg_handler.debug_verbose
    end

    def delete_visit(visit_id)
      visit = Ahoy::Visit.where(id: visit_id);return if visit.blank?
      Ahoy::Event.where(visit_id: visit_id).each { |row| row.delete }
      visit.each { |visit| visit.delete }
    end

    def delete_visit_reason(ip)
      return "crawler_ip" if crawler_ip?(ip)
      return "high_visit_count" if high_visit_count?(ip)
      return "high_visit_event_count" if high_visit_event_count?(ip)
      return "high_event_count" if high_event_count?(ip)
      return ""
    end

    def delete_visits
      return unless @delete
      @ips.keys.each do |ip|
        delete_visits_by_ip(ip) unless delete_visit_reason(ip).blank?
      end
    end

    def delete_visits_by_ip(ip)
      @ips[ip][:visit_ids].each { |visit_id| delete_visit( visit_id ) }
    end

    def events( begin_date, end_date )
      ::Ahoy::Event.where(['time >= ? AND time < ?', begin_date, end_date])
    end

    def expand_report_dir_path_partials( path )
      path = path.gsub( /\%report_path\%/, report_path() )
      rv = ::Deepblue::ReportHelper.expand_path_partials( path )
      rv += "/" unless rv.ends_with? "/"
      return rv
    end

    def report_path
      hostname = hostname_short
      return './data/ahoy/' if 'local' == hostname
      return '/deepbluedata-prep/ahoy/'
    end

    def high_visit_count?(ip)
      @ips[ip][:visit_ids].size > ( @span_days * @high_visit_count_per_day )
    end

    def high_visit_event_count?(ip)
      ip_count = @ips[ip][:visit_ids].size
      high = @span_days * @high_visit_event_count_per_day
      return true if ip_count > high && @ips[ip][:event_count] <= ip_count
      return false
    end

    def high_event_count?(ip)
      @ips[ip][:event_count] > @high_event_count
    end

    def msg_handler
      @msg_handler ||= msg_handler_init
    end

    def msg_handler_init
      rv = ::Deepblue::MessageHandler.new( debug_verbose: @debug_verbose, to_console: @task, verbose: @verbose )
      rv.quiet = @quiet
      return rv
    rescue Exception => e
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      return ::Deepblue::MessageHandler.new
    end

    def save_ips(file)
      CSV.open( file, 'w', {:force_quotes=>true} ) do |out|
        out << %w[ ip visit_count event_count delete_visit_reason(ip) ]
        @ips.keys.each do |ip|
          ip_info = @ips[ip]; out << [ ip, ip_info[:visit_ids].size, ip_info[:event_count], delete_visit_reason(ip) ]
        end
      end
    end

    def save_rows(file,rows)
      CSV.open( file, 'w', {:force_quotes=>true} ) do |out|
        out << %w[ started_at id ip event_count user_agent ]
        rows.each do |row|
          event_count = Ahoy::Event.where(visit_id: row.id).size
          out << [ row.id, row.started_at, row.ip, event_count, row.user_agent ]
          add_ip(row,event_count)
        end
      end
    end

    def summarize_ips(file,ips=nil,begin_date=nil,end_date=nil)
      delete_reasons = %w[ crawler_ip high_visit_count high_visit_event_count high_event_count ]
      if ips.blank?
        delete_reasons2 = [];delete_reasons.each do |reason|
          delete_reasons2 << "visit_#{reason}"
          delete_reasons2 << "event_#{reason}"
        end
        CSV.open( file, 'w', {:force_quotes=>true} ) do |out|
          out << %w[ begin_date
                     end_date
                     ips_found
                     total_visits
                     total_events
                     visits_targeted_for_delete
                     events_targeted_for_delete ] + delete_reasons2
        end
        return
      end
      deletes = {};delete_reasons.each do |reason|
        deletes["visit_#{reason}"] = 0
        deletes["event_#{reason}"] = 0
      end
      total_visits = 0
      total_events = 0
      visits_targeted_for_delete = 0
      events_targeted_for_delete = 0
      ips.keys.each do |ip|
        ip_info = ips[ip]
        total_visits += ip_info[:visit_ids].size
        total_events += ip_info[:event_count]
        reason = delete_visit_reason(ip)
        if reason.present?
          visits_targeted_for_delete += ip_info[:visit_ids].size
          events_targeted_for_delete += ip_info[:event_count]
          deletes["visit_#{reason}"] += ip_info[:visit_ids].size
          deletes["event_#{reason}"] += ip_info[:event_count]
        end
      end
      deletes2 = [];deletes.keys.each { |key| deletes2 << deletes[key] }
      CSV.open( file, 'a', {:force_quotes=>true} ) do |out|
        out << [ begin_date.strftime('%Y%m%d'),
                 end_date.strftime('%Y%m%d'),
                 ips.size,
                 total_visits,
                 total_events,
                 visits_targeted_for_delete,
                 events_targeted_for_delete ] + deletes2
      end
    end

    def visits( begin_date, end_date )
      ::Ahoy::Visit.where(['started_at >= ? AND started_at < ?', begin_date, end_date])
    end

  end

end
