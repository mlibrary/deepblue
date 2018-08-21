# frozen_string_literal: true

module Deepblue

  # rubocop:disable Metrics/ParameterLists
  class LogReporter < LogReader

    attr_reader :lines_reported
    attr_reader :output, :output_close, :output_mode, :output_pathname

    attr_reader :timestamp_first, :timestamp_last
    attr_reader :class_events
    attr_reader :events
    attr_reader :ids

    def initialize( filter: nil, input:, options: {} )
      super( filter: filter, input: input, options: options )
      add_date_range_filter
    end

    # rubocop:disable Rails/Output
    def report
      run
      # TODO: pretty output
      puts "timestamp_first = #{@timestamp_first}"
      puts "timestamp_last = #{@timestamp_last}"
      puts "ids = #{ids}"
      puts "events = #{events}"
      puts "class_events = #{class_events}"
    end
    # rubocop:enable Rails/Output

    def run
      initialize_report_values
      readlines do |line, timestamp, event, event_note, class_name, id, raw_key_values|
        line_read( line, timestamp, event, event_note, class_name, id, raw_key_values )
      end
    end

    protected

      def add_date_range_filter
        begin_timestamp = option( key: 'begin_timestamp', default_value: nil )
        end_timestamp = option( key: 'end_timestamp', default_value: nil )
        timestamp_format = option( key: 'timestamp_format', default_value: '' )
        return if begin_timestamp.blank? && end_timestamp.blank?
        date_range_filter = DateLogFilter.new( begin_timestamp: begin_timestamp,
                                               end_timestamp: end_timestamp,
                                               timestamp_format: timestamp_format )
        filter_and( new_filters: date_range_filter )
      end

      def class_event_key( class_name:, event: )
        "#{class_name}_#{event}"
      end

      def initialize_report_values
        @lines_reported = 0
        @timestamp_first = nil
        @timestamp_last = nil
        @events = Hash.new { |h, k| h[k] = 0 }
        @class_events = Hash.new { |h, k| h[k] = 0 }
        @ids = {}
      end

      def line_read( _line, timestamp, event, _event_note, class_name, id, _raw_key_values )
        @lines_reported += 1
        @timestamp_first = timestamp if @timestamp_first.blank?
        @timestamp_last = timestamp
        @ids[id] = true unless @ids.key? id
        @events[event] = @events[event] + 1
        class_event_key = class_event_key( class_name: class_name, event: event )
        @class_events[class_event_key] = @class_events[class_event_key] + 1
      end

  end
  # rubocop:enable Metrics/ParameterLists

end
