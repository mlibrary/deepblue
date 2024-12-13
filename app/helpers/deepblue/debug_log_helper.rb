# frozen_string_literal: true

module Deepblue

  module DebugLogHelper

    extend JsonLoggerHelper
    extend JsonLoggerHelper::ClassMethods

    mattr_accessor :debug_log_helper_debug_verbose, default: false

    # rubocop:disable Style/ClassVars
    def self.echo_to_rails_logger
      @@echo_to_rails_logger ||= false
    end

    def self.echo_to_rails_logger=( echo_to_rails_logger )
      @@echo_to_rails_logger = echo_to_rails_logger
    end
    # rubocop:enable Style/ClassVars

    def self.log_entries( begin_date: nil, end_date: nil )
      debug_verbose = debug_log_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "begin_date=#{begin_date}",
                                             "end_date=#{end_date}",
                                             "" ] if debug_verbose
      rv = ::Deepblue::JsonLoggerHelper.log_entries( file_path: DebugLogger.log_file,
                                                     begin_date: begin_date,
                                                     end_date: end_date )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "entry count=#{rv.size}",
                                             "" ] if debug_verbose
      return rv
    end

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: 'unknown_id',
                  timestamp: timestamp_now,
                  time_zone: timestamp_zone,
                  echo_to_rails_logger: DebugLogHelper.echo_to_rails_logger,
                  logger: DEBUG_LOGGER,
                  **log_key_values )

      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        time_zone: time_zone,
                        **log_key_values )
      log_raw msg
      Rails.logger.info '+++++++++++++++++++++++++++++++++' if echo_to_rails_logger
      Rails.logger.info msg if echo_to_rails_logger
      Rails.logger.info '+++++++++++++++++++++++++++++++++' if echo_to_rails_logger
      true # hyrax5
    end

    def self.log_key_values_to_table( key_values,
                                      on_key_values_to_table_body_callback: nil,
                                      parse: false,
                                      row_key_value_callback: nil,
                                      debug_verbose: debug_log_helper_debug_verbose )

      debug_verbose ||= debug_log_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "key_values=#{key_values}",
                                             "parse=#{parse}",
                                             "" ] if debug_verbose
      JsonHelper.key_values_to_table( key_values,
                                      on_key_values_to_table_body_callback: on_key_values_to_table_body_callback,
                                      parse: parse,
                                      row_key_value_callback: row_key_value_callback,
                                      debug_verbose: debug_verbose )
    end

    def self.log_parse_entry( entry, line_number: 0 )
      debug_verbose = debug_log_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "line_number=#{line_number}",
                                             "entry=#{entry}",
                                             "" ] if debug_verbose
      rv = ::Deepblue::JsonLoggerHelper.log_entry_parse( entry, line_number: line_number )
      return rv
    end

    def self.log_raw( msg )
      DEBUG_LOGGER.info( msg )
    end

  end

end
