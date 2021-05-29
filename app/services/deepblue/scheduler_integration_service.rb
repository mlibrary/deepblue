# frozen_string_literal: true

module Deepblue

  module SchedulerIntegrationService

    mattr_accessor :scheduler_integration_service_debug_verbose, default: false

    include ::Deepblue::InitializationConstants

    @@_setup_failed = false
    @@_setup_ran = false

    mattr_accessor :scheduler_job_file_path
    mattr_accessor :scheduler_active
    mattr_accessor :scheduler_heartbeat_email_targets, default: [ 'fritx@umich.edu' ].freeze # leave empty to disable
    mattr_accessor :scheduler_log_echo_to_rails_logger, default: true
    mattr_accessor :scheduler_start_job_default_delay, default: 5.minutes
    mattr_accessor :scheduler_started_email, default: []

    # mattr_accessor :scheduler_active,
    #                :scheduler_log_echo_to_rails_logger,
    #                :scheduler_heartbeat_email_targets,
    #                :scheduler_job_file_path,
    #                :scheduler_start_job_default_delay,
    #                :scheduler_started_email

    def self.setup
      return if @@_setup_ran == true
      @@_setup_ran = true
      begin
        yield self
      rescue Exception => e # rubocop:disable Lint/RescueException
        @@_setup_failed = true
      end
    end

    def self.scheduler_pid
      `pgrep -fu #{Process.uid} resque-scheduler`
    end

    def self.scheduler_restart( user:, debug_verbose: scheduler_integration_service_debug_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "user=#{user}",
                                             "" ] if debug_verbose
      SchedulerStartJob.perform_later( job_delay: 0,
                                       restart: true,
                                       user_email: user.email,
                                       debug_verbose: debug_verbose )
    end

    def self.scheduler_running
      scheduler_pid.present?
    end

    def self.scheduler_start( user:, debug_verbose: scheduler_integration_service_debug_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "user=#{user}",
                                             "" ] if debug_verbose
      SchedulerStartJob.perform_later( job_delay: 0,
                                       restart: false,
                                       user_email: user.email,
                                       debug_verbose: debug_verbose )
    end

    def self.scheduler_stop( debug_verbose: scheduler_integration_service_debug_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "scheduler_running=#{scheduler_running}",
                                             "user=#{user}",
                                             "" ] if debug_verbose
      pid = scheduler_pid
      `kill -15 #{pid}` if pid.present?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "scheduler_running=#{scheduler_running}",
                                             "user=#{user}",
                                             "" ] if debug_verbose
    end

  end

end
