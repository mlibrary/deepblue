# frozen_string_literal: true

module Hyrax

  require './lib/hyrax/contact_form_logger'

  module ContactFormHelper

    extend ::Deepblue::JsonLoggerHelper
    extend ::Deepblue::JsonLoggerHelper::ClassMethods

    mattr_accessor :contact_form_helper_debug_verbose, default: false

    mattr_accessor :contact_form_log_echo_to_rails_logger,
                   default: ContactFormIntegrationService.contact_form_log_echo_to_rails_logger

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: '',
                  timestamp: timestamp_now,
                  echo_to_rails_logger: contact_form_log_echo_to_rails_logger,
                  contact_method:,
                  category:,
                  name:,
                  email:,
                  subject:,
                  message:,
                  **log_key_values )

      log_key_values = log_key_values.merge( contact_method: contact_method,
                                             category: category,
                                             name: name,
                                             email: email,
                                             subject: subject,
                                             message: message )
      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        time_zone: ::Deepblue::LoggingHelper.timestamp_zone,
                        **log_key_values )
      # puts msg
      log_raw msg
      Rails.logger.info msg if echo_to_rails_logger
    end

    def self.log_entries( begin_date: nil, end_date: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "begin_date=#{begin_date}",
                                             "end_date=#{end_date}",
                                             "" ] if contact_form_helper_debug_verbose
      file_path = ContactFormLogger.log_file
      if File.exist?( file_path )
        rv = log_read_entries( file_path, begin_date: begin_date, end_date: end_date )
      else
        rv = []
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "entry count=#{rv.size}",
                                             "" ] if contact_form_helper_debug_verbose
      return rv
    end

    def self.log_raw( msg )
      CONTACT_FORM_LOGGER.info( msg )
    end

    def self.log_entry_filter_in( begin_date: nil, end_date: nil, line:, line_number: )
      return true if begin_date.blank? && end_date.blank?
      timestamp, _event, _event_note, _class_name, _id, _key_values = parse_log_line( line,
                                                                                      line_number: line_number,
                                                                                      raw_key_values: true )
      timestamp = parse_timestamp( timestamp )
      return timestamp <= end_date if begin_date.blank?
      return timestamp >= begin_date if end_date.blank?
      return timestamp >= begin_date && timestamp <= end_date
    end

    def self.log_key_values_to_table( key_values, parse: false )
      JsonHelper.key_values_to_table( key_values, parse: parse )
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

    def self.log_read_entries( file_path, begin_date: nil, end_date: nil )
      entries = []
      i = 0
      File.open( file_path, "r" ) do |fin|
        until fin.eof?
          begin
            line = fin.readline
            line.chop!
            entries << line if log_entry_filter_in( begin_date: begin_date, end_date: end_date, line: line, line_number: i )
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
