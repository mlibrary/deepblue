# frozen_string_literal: true

module Deepblue

  require_relative './json_logger_helper'

  module ProvenanceHelper

    extend JsonLoggerHelper
    extend JsonLoggerHelper::ClassMethods

    # def self.included( base )
    #   base.extend( JsonLoggerHelper::ClassMethods )
    # end

    # rubocop:disable Style/ClassVars
    def self.echo_to_rails_logger
      @@echo_to_rails_logger ||= DeepBlueDocs::Application.config.provenance_log_echo_to_rails_logger
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
                  time_zone: timestamp_zone,
                  echo_to_rails_logger: ProvenanceHelper.echo_to_rails_logger,
                  **log_key_values )

      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        time_zone: time_zone,
                        **log_key_values )
      log_raw msg
      Rails.logger.info msg if echo_to_rails_logger
    end

    def self.log_raw( msg )
      PROV_LOGGER.info( msg )
    end

  end

end
