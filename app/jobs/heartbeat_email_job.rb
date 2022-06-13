# frozen_string_literal: true

class HeartbeatEmailJob < ::Deepblue::DeepblueJob

  mattr_accessor :heartbeat_email_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.heartbeat_email_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

heartbeat_email_job:
  # Run once a day, one minute after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H
  # cron: '*/5 * * * *'
  cron: '1 5 * * *'
  # rails_env: production
  class: HeartbeatEmailJob
  queue: scheduler
  description: Heartbeat email job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      # - 'staging.deepblue.lib.umich.edu'
      # - 'testing.deepblue.lib.umich.edu'
    subscription_service_id: heartbeat_email_job

END_OF_SCHEDULER_ENTRY
  queue_as :scheduler

  attr_accessor :subscription_service_id

  def self.perform( *args )
    HeartbeatEmailJob.perform_now( args )
  end

  def perform( *args )
    event = "heartbeat email job"
    # puts "args=#{args}"
    initialize_options_from( *args, debug_verbose: heartbeat_email_job_debug_verbose )
    # puts "options=#{options}"
    allowed = hostname_allowed?(debug_verbose: heartbeat_email_job_debug_verbose)
    # puts "hostname_allowed?=#{allowed}"
    log( event: event, hostname_allowed: allowed )
    return job_finished unless allowed
    from_config = ::Deepblue::SchedulerIntegrationService.scheduler_heartbeat_email_targets.dup
    find_all_email_targets( additional_email_targets: from_config )
    email_all_targets( task_name: "scheduler heartbeat", event: event )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise e
  end

end
