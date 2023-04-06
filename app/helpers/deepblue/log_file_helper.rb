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
        rv = Deepblue::JsonLoggerHelper.log_read_entries( log_file_path,
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
      return ::Deepblue::JsonLoggerHelper.log_entry_parse( entry, line_number: line_number )
    end

  end

end
