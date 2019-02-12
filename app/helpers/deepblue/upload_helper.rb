# frozen_string_literal: true

module Deepblue

  require './lib/upload_logger'
  require_relative './json_logger_helper'

  module UploadHelper

    extend JsonLoggerHelper
    extend JsonLoggerHelper::ClassMethods

    # rubocop:disable Style/ClassVars
    def self.echo_to_rails_logger
      @@echo_to_rails_logger ||= DeepBlueDocs::Application.config.upload_log_echo_to_rails_logger
    end

    def self.echo_to_rails_logger=( echo_to_rails_logger )
      @@echo_to_rails_logger = echo_to_rails_logger
    end
    # rubocop:enable Style/ClassVars

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: 'unknown_id',
                  timestamp: timestamp_now,
                  echo_to_rails_logger: UploadHelper.echo_to_rails_logger,
                  **log_key_values )

      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
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
