# frozen_string_literal: true

module Deepblue

  class LogExtracter < LogReader

    attr_reader :lines_extracted

    def initialize( filter: nil, input:, extract_parsed_tuple: false, options: {} )
      super( filter: filter, input: input, options: options )
      @extract_parsed_tuple = extract_parsed_tuple
      @lines_extracted = []
    end

    def extract_line( line, timestamp, event, event_note, class_name, id, raw_key_values )
      if @extract_parsed_tuple
        @lines_extracted << [line, timestamp, event, event_note, class_name, id, raw_key_values]
      else
        @lines_extracted << line
      end
    end

    def run
      readlines do |line, timestamp, event, event_note, class_name, id, raw_key_values|
        extract_line line, timestamp, event, event_note, class_name, id, raw_key_values
      end
    end

  end

end
