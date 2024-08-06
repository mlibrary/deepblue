# frozen_string_literal: true

class ResetCondensedEventsJob < ::Deepblue::DeepblueJob

  mattr_accessor :reset_condensed_events_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.reset_condensed_events_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

reset_condensed_events_job:
  # Run on demand
  #      M H D
  # cron: '*/5 * * * *'
  cron: '25 5 * * *'
  class: ResetCondensedEventsJob
  queue: scheduler
  description: Reset the condensed events job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    quiet: true
    by_request_only: true
    subscription_service_id: reset_condensed_events_job         

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  def perform( *args )
    initialize_options_from( args: args, debug_verbose: reset_condensed_events_job_debug_verbose )
    return job_finished unless hostname_allowed?
    msg_handler.msg "Start processing at #{DateTime.now}"
    log( event: "reset condensed events job", hostname_allowed: hostname_allowed? )
    msg_handler.msg "Start dropping condensed events at #{DateTime.now}"
    ::AnalyticsHelper.drop_condensed_event_downloads
    msg_handler.msg "Done dropping condensed events at #{DateTime.now}"
    msg_handler.msg "Start initializing condensed events at #{DateTime.now}"
    ::AnalyticsHelper.initialize_condensed_event_downloads
    msg_handler.msg "Done initializing condensed events at #{DateTime.now}"

    job_finished
    msg_handler.msg "Finished processing at #{DateTime.now}"
    email_results
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise
  end
  
end
