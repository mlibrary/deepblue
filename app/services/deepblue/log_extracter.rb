# frozen_string_literal: true

module Deepblue

  class LogExtracter < LogReader

    attr_reader :lines_extracted

    def initialize( filter: nil, input:, options: {} )
      super( filter: filter, input: input, options: options )
      @lines_extracted = []
    end

    def extract_line( line, timestamp, event, event_note, class_name, id, raw_key_values )
      @lines_extracted << line
    end

    def run
      readlines do |line, timestamp, event, event_note, class_name, id, raw_key_values|
        extract_line line, timestamp, event, event_note, class_name, id, raw_key_values
      end
    end

  end

end
