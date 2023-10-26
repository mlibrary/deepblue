# frozen_string_literal: true

module Ahoy

  class DanglingEventCleaner < AbstractCleaner

    def self.Test( begin_date: AHOY_ERA_START,
                   trim_date: DateTime.now + INC_DAY,
                   inc: INC_DAY,
                   span: SPAN_DAY,
                   span_days: 1 )

      DanglingEventCleaner.new( begin_date: begin_date,
                                trim_date: trim_date,
                                delete: false,
                                inc: inc,
                                span: span,
                                span_days: span_days )
    end

    mattr_accessor :ahoy_dangling_event_cleaner_debug_verbose, default: false

    def initialize( begin_date: AHOY_ERA_START,
                    trim_date: DateTime.now + INC_DAY,
                    delete: true,
                    inc: INC_DAY,
                    span: SPAN_DAY,
                    span_days: 1,
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

    end

    def run
      @ips = {}
      while ( trim_date > begin_date )
        end_date = begin_date + inc
        msg_handler.msg "Starting: >= #{begin_date} to < #{end_date}"
        rows = events( begin_date, end_date )
        if 0 == rows.size
          msg_handler.msg "  Skipped: >= #{begin_date} to < #{end_date}"
        else
          processed = 0
          msg_handler.msg "  Processing #{rows.size} rows..."
          rows.each do |row|
            visit = ::Ahoy::Visit.where( id: row.visit_id )
            if visit.blank?
              processed += 1
              row.delete if delete
            end
          end
          msg_handler.msg "  Finished: >= #{begin_date} to < #{end_date} -- processed #{processed} rows."
        end
        begin_date = end_date
      end
    end

  end

end
