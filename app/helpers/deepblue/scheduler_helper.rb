# frozen_string_literal: true

module Deepblue

  require './lib/scheduler_logger'

  module SchedulerHelper

    extend JsonLoggerHelper
    extend JsonLoggerHelper::ClassMethods

    mattr_accessor :scheduler_log_echo_to_rails_logger,
                   default: ::Deepblue::SchedulerIntegrationService.scheduler_log_echo_to_rails_logger

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: '',
                  hostname_allowed: "N/A",
                  timestamp: timestamp_now,
                  echo_to_rails_logger: scheduler_log_echo_to_rails_logger,
                  **log_key_values )

      log_key_values = log_key_values.merge( hostname_allowed: hostname_allowed )
      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        time_zone: LoggingHelper.timestamp_zone,
                        **log_key_values )
      # puts msg
      log_raw msg
      Rails.logger.info msg if echo_to_rails_logger
      true # hyrax5
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
