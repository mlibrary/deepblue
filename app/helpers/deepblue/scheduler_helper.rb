# frozen_string_literal: true

module Deepblue

  require './lib/scheduler_logger'

  module SchedulerHelper

    extend JsonLoggerHelper
    extend JsonLoggerHelper::ClassMethods

    # rubocop:disable Style/ClassVars
    def self.echo_to_rails_logger
      @@echo_to_rails_logger ||= DeepBlueDocs::Application.config.scheduler_log_echo_to_rails_logger
    end

    def self.echo_to_rails_logger=( echo_to_rails_logger )
      @@echo_to_rails_logger = echo_to_rails_logger
    end
    # rubocop:enable Style/ClassVars

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: '',
                  timestamp: timestamp_now,
                  echo_to_rails_logger: SchedulerHelper.echo_to_rails_logger,
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
      SCHEDULER_LOGGER.info( msg )
    end

  end

end
