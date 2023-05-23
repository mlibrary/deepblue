# frozen_string_literal: true

module Deepblue

  class LogExtracter < LogReader

    attr_reader :lines_extracted, :max_lines_extracted

    def initialize( filter: nil, input:, extract_parsed_tuple: false, options: {} )
      super( filter: filter, input: input, options: options )
      @extract_parsed_tuple = extract_parsed_tuple
      @lines_extracted = []
      @max_lines_extracted = option( key: 'max_lines_extracted', default_value: -1 )
    end

    def extract_line( _reader, line, timestamp, event, event_note, class_name, id, raw_key_values )
      if @extract_parsed_tuple
        @lines_extracted << [line, timestamp, event, event_note, class_name, id, raw_key_values]
      else
        @lines_extracted << line
      end
    end

    def run
      if 1 > max_lines_extracted
        readlines do |reader, line, timestamp, event, event_note, class_name, id, raw_key_values|
          extract_line( reader, line, timestamp, event, event_note, class_name, id, raw_key_values )
        end
      else
        readlines do |reader, line, timestamp, event, event_note, class_name, id, raw_key_values|
          break if @lines_extracted.size > @max_lines_extracted
          extract_line( reader, line, timestamp, event, event_note, class_name, id, raw_key_values )
        end
      end
      return lines_extracted
    end

  end

end
