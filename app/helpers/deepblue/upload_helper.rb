# frozen_string_literal: true

module Deepblue

  require './lib/upload_logger'

  module UploadHelper

    extend JsonLoggerHelper
    extend JsonLoggerHelper::ClassMethods

    mattr_accessor :upload_log_echo_to_rails_logger,
                   default: Rails.configuration.upload_log_echo_to_rails_logger

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: 'unknown_id',
                  timestamp: timestamp_now,
                  echo_to_rails_logger: upload_log_echo_to_rails_logger,
                  **log_key_values )

      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        time_zone: LoggingHelper.timestamp_zone,
                        **log_key_values )
      log_raw msg
      Rails.logger.info msg if echo_to_rails_logger
    end

    def self.log_raw( msg )
      UPLOAD_LOGGER.info( msg )
    end

    def self.uploaded_file_id( uploaded_file )
      return nil unless uploaded_file.respond_to? :id
      uploaded_file.id
    end

    def self.uploaded_file_path( uploaded_file )
      uploaded_file.file.path
    end

    def self.uploaded_file_size( uploaded_file )
      File.size uploaded_file.file.path
    end

  end

end
