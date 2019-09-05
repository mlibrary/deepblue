# frozen_string_literal: true

module Deepblue

  require_relative './log_filter'
  require_relative './log_reporter'

  # rubocop:disable Metrics/ParameterLists
  class IngestFixityLogReporter < LogReporter

    attr_reader :fixity_check_failed_id, :fixity_check_passed_id

    def initialize( filter: nil, input:, options: {} )
      super( filter: Deepblue::FixityCheckLogFilter.new, input: input, options: options )
      filter_and( new_filters: filter ) if filter.present?
    end

    # rubocop:disable Rails/Output
    def report
      run
      # TODO: pretty output
      puts "timestamp_first = #{timestamp_first}"
      puts "timestamp_last = #{timestamp_last}"
      # puts "ids = #{ids}"
      # puts "events = #{events}"
      # puts "class_events = #{class_events}"
      puts "fixity_check_passed_count = #{fixity_check_passed_id.size}"
      puts "fixity_check_failed_count = #{fixity_check_failed_id.size}"
    end
    # rubocop:enable Rails/Output

    protected

      def initialize_report_values
        super()
        @fixity_check_failed_id = []
        @fixity_check_passed_id = []
      end

      def line_read( line, timestamp, event, event_note, class_name, id, raw_key_values )
        super( line, timestamp, event, event_note, class_name, id, raw_key_values )
        if 'success' == event_note
          @fixity_check_passed_id << id
        else
          @fixity_check_failed_id << id
        end
      end

  end
  # rubocop:enable Metrics/ParameterLists

end
