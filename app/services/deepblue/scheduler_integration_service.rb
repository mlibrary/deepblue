# frozen_string_literal: true

module Deepblue

  module SchedulerIntegrationService

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false

    @@scheduler_job_file_path
    @@scheduler_active
    @@scheduler_heartbeat_email_targets = [ 'fritx@umich.edu' ].freeze # leave empty to disable
    @@scheduler_log_echo_to_rails_logger = true
    @@scheduler_start_job_default_delay = 5.minutes

    mattr_accessor :scheduler_active,
                   :scheduler_log_echo_to_rails_logger,
                   :scheduler_heartbeat_email_targets,
                   :scheduler_job_file_path,
                   :scheduler_start_job_default_delay

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    def self.scheduler_pid
      `pgrep -fu #{Process.uid} resque-scheduler`
    end

    def self.scheduler_restart
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ]
      SchedulerStartJob.perform_later( job_delay: 0, restart: true )
    end

    def scheduler_running
      scheduler_pid.present?
    end

    def self.scheduler_start
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ]
      SchedulerStartJob.perform_later( job_delay: 0, restart: false )
    end

    def self.scheduler_stop
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "scheduler_running=#{scheduler_running}",
                                             "" ]
      pid = scheduler_pid
      `kill -9 #{pid}` if pid.present?
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "scheduler_running=#{scheduler_running}",
                                             "" ]
    end

  end

end
