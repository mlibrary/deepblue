# frozen_string_literal: true

module Deepblue

  module SchedulerIntegrationService

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :scheduler_integration_service_debug_verbose, default: false

    mattr_accessor :scheduler_job_file_path
    mattr_accessor :scheduler_active
    mattr_accessor :scheduler_autostart_servers, default: []
    mattr_accessor :scheduler_autostart_emails, default: [ 'fritx@umich.edu' ].freeze # leave empty to disable
    mattr_accessor :scheduler_heartbeat_email_targets, default: [ 'fritx@umich.edu' ].freeze # leave empty to disable
    mattr_accessor :scheduler_log_echo_to_rails_logger, default: true
    mattr_accessor :scheduler_start_job_default_delay, default: 5.minutes
    mattr_accessor :scheduler_started_email, default: []

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

    def self.scheduler_autostart( debug_verbose: scheduler_integration_service_debug_verbose )
      # puts "scheduler_autostart" if debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "scheduler_active=#{scheduler_active}",
                                             "" ], bold_puts: true if debug_verbose
      return unless scheduler_active
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "scheduler_autostart_servers=#{scheduler_autostart_servers}",
                                             "Rails.configuration.hostname=#{Rails.configuration.hostname}",
                                             "include? hostname=#{scheduler_autostart_servers.include? Rails.configuration.hostname}",
                                             "" ], bold_puts: true if debug_verbose
      return unless scheduler_autostart_servers.include? Rails.configuration.hostname
      # puts "Calling SchedulerStartJob.perform_later" if debug_verbose
      SchedulerStartJob.perform_later( autostart: true,
                                       job_delay: 0,
                                       restart: false,
                                       user_email: scheduler_autostart_emails,
                                       debug_verbose: debug_verbose )
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
