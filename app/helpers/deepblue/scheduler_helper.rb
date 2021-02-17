# frozen_string_literal: true

module Deepblue

  require './lib/scheduler_logger'

  module SchedulerHelper

    extend JsonLoggerHelper
    extend JsonLoggerHelper::ClassMethods

    # rubocop:disable Style/ClassVars
    def self.echo_to_rails_logger
      @@echo_to_rails_logger ||= ::Deepblue::SchedulerIntegrationService.scheduler_log_echo_to_rails_logger
    end

    def self.echo_to_rails_logger=( echo_to_rails_logger )
      @@echo_to_rails_logger = echo_to_rails_logger
    end
    # rubocop:enable Style/ClassVars

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: '',
                  hostname_allowed: "N/A",
                  timestamp: timestamp_now,
                  echo_to_rails_logger: SchedulerHelper.echo_to_rails_logger,
                  **log_key_values )

      log_key_values = log_key_values.merge( hostname_allowed: hostname_allowed )
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

    def self.scheduler_pid
      ::Deepblue::SchedulerIntegrationService.scheduler_pid
    end

    def self.scheduler_running
      scheduler_pid.present?
    end

    def self.scheduler_status
      return MsgHelper.t( "hyrax.scheduler.running") if scheduler_running
      MsgHelper.t( 'hyrax.scheduler.not_running_html' )
    end

  end

end
