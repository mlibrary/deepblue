# frozen_string_literal: true

module Ahoy

  class VisitsCleaner < AbstractCleaner

    DEFAULT_REPORT_DIR = '%report_path%/%date%/'

    def self.Test( begin_date: AHOY_ERA_START,
                   trim_date: DateTime.now + INC_DAY,
                   inc: INC_DAY,
                   report_dir: DEFAULT_REPORT_DIR,
                   span: SPAN_DAY,
                   span_days: 1 )

      VisitsCleaner.new( begin_date: begin_date,
                         trim_date: trim_date,
                         delete: false,
                         inc: inc,
                         report_dir: report_dir,
                         span: span,
                         span_days: span_days )
    end

    mattr_accessor :ahoy_dangling_event_cleaner_debug_verbose, default: false

    def initialize( begin_date: AHOY_ERA_START,
                    trim_date: DateTime.now.beginning_of_day,
                    delete: true,
                    inc: INC_WEEK,
                    report_dir: DEFAULT_REPORT_DIR,
                    span: SPAN_WEEK,
                    span_days: 7,
                    msg_handler: nil,
                    quiet: false,
                    task: false,
                    verbose: false,
                    debug_verbose: ahoy_dangling_event_cleaner_debug_verbose )

      super( begin_date: begin_date,
             trim_date: trim_date,
             delete: delete,
             inc: inc,
             span: span,
             span_days: span_days,
             msg_handler: msg_handler,
             quiet: quiet,
             task: task,
             verbose: verbose,
             debug_verbose: debug_verbose )

      @report_dir = expand_report_dir_path_partials( report_dir )
      @report_base_filename = "#{span}_visits.csv"
      @report_summary="#{@report_dir}summary_#{@report_base_filename}"
      Dir.mkdir( @report_dir ) unless Dir.exist?( @report_dir )

      # @trim_date=DateTime.new(2023,10,24).beginning_of_day

    end

    def run
      @ips = {}
      summarize_ips( @report_summary )
      while ( trim_date > @begin_date )
        end_date = @begin_date + inc
        msg_handler.msg "Starting: >= #{@begin_date} to < #{end_date}"
        rows = visits( begin_date, end_date )
        if 0 == rows.size
          msg_handler.msg "  Skipped: >= #{@begin_date} to < #{end_date}"
        else
          msg_handler.msg "  Processing #{rows.size} rows..."
          save_rows( "#{@report_dir}#{@begin_date.strftime('%Y%m%d')}_#{@report_base_filename}", rows )
          save_ips( "#{@report_dir}#{@begin_date.strftime('%Y%m%d')}_ip_#{@report_base_filename}" )
          summarize_ips( @report_summary, @ips, @begin_date, end_date)
          delete_visits
          @ips = {}
          msg_handler.msg "  Finished: >= #{@begin_date} to < #{end_date}"
        end
        @begin_date = end_date
      end
    end

  end

end
