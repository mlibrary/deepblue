# frozen_string_literal: true

module Deepblue

  module SchedulerIntegrationService

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false

    @@scheduler_active
    @@scheduler_heartbeat_email_targets = [ 'fritx@umich.edu' ].freeze # leave empty to disable
    @@scheduler_job_file = 'scheduler_jobs_prod.yml'
    @@scheduler_log_echo_to_rails_logger = true
    @@scheduler_start_job_default_delay = 5.minutes

    mattr_accessor :scheduler_active,
                   :scheduler_log_echo_to_rails_logger,
                   :scheduler_heartbeat_email_targets,
                   :scheduler_job_file,
                   :scheduler_start_job_default_delay

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

  end

end
