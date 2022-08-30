# frozen_string_literal: true

module Deepblue

  require './lib/hyrax/contact_form_logger'

  module LogFileHelper

    extend ::Deepblue::JsonLoggerHelper
    extend ::Deepblue::JsonLoggerHelper::ClassMethods

    mattr_accessor :log_file_helper_debug_verbose, default: false

    def self.log_entries( log_file_path:, begin_date: nil, end_date: nil, raw_key_values: true )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "log_file_path=#{log_file_path}",
                                             "begin_date=#{begin_date}",
                                             "end_date=#{end_date}",
                                             "" ] if log_file_helper_debug_verbose
      if File.exist?( log_file_path )
        rv = log_read_entries( log_file_path,
                               begin_date: begin_date,
                               end_date: end_date,
                               raw_key_values: raw_key_values )
      else
        rv = []
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "entry count=#{rv.size}",
                                             "" ] if log_file_helper_debug_verbose
      return rv
    end

    def self.log_entry_filter_in( begin_date: nil, end_date: nil, line:, line_number:, raw_key_values: true )
      return true if begin_date.blank? && end_date.blank?
      timestamp, _event, _event_note, _class_name, _id, _key_values = parse_log_line( line,
                                                                                      line_number: line_number,
                                                                                      raw_key_values: raw_key_values )
      timestamp = parse_timestamp( timestamp )
      return timestamp <= end_date if begin_date.blank?
      return timestamp >= begin_date if end_date.blank?
      return timestamp >= begin_date && timestamp <= end_date
    end

    def self.log_key_values_to_table( key_values,
                                      on_key_values_to_table_body_callback: nil,
                                      parse: false,
                                      row_key_value_callback: nil,
                                      debug_verbose: log_file_helper_debug_verbose )

      debug_verbose ||= log_file_helper_debug_verbose
      JsonHelper.key_values_to_table( key_values,
                                      on_key_values_to_table_body_callback: on_key_values_to_table_body_callback,
                                      parse: parse,
                                      row_key_value_callback: row_key_value_callback,
                                      debug_verbose: debug_verbose )
    end

    def self.log_parse_entry( entry, line_number: 0 )
      # line is of the form: "timestamp event/event_note/class_name/id key_values"
      timestamp = nil
      event = nil
      event_note = nil
      class_name = nil
      id = nil
      raw_key_values = nil
      timestamp, event, event_note, class_name, id,
        raw_key_values = parse_log_line( entry, line_number: line_number, raw_key_values: true )
      return { timestamp: timestamp, event: event, event_note: event_note, class_name: class_name, id: id,
               raw_key_values: raw_key_values, line_number: line_number, parse_error: nil }
    rescue LogParseError => e
      return { entry: entry, line_number: line_number, parse_error: e }
    end

    def self.log_read_entries( log_file_path, begin_date: nil, end_date: nil, raw_key_values: true )
      entries = []
      i = 0
      File.open( log_file_path, "r" ) do |fin|
        until fin.eof?
          begin
            line = fin.readline
            line.chop!
            entries << line if log_entry_filter_in( begin_date: begin_date,
                                                    end_date: end_date,
                                                    line: line,
                                                    line_number: i,
                                                    raw_key_values: raw_key_values )
          rescue EOFError
            line = nil
          end
          i += 1
        end
      end
      return entries
    end

  end

end
