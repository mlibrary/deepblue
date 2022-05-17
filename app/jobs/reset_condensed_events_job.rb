# frozen_string_literal: true

class ResetCondensedEventsJob < ::Deepblue::DeepblueJob

  mattr_accessor :reset_condensed_events_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.reset_condensed_events_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

update_condensed_events_job:
  # Run once a day, twenty-five minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
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
    job_msg_queue << "Start processing at #{DateTime.now}"    
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if reset_condensed_events_job_debug_verbose
    initialize_options_from( *args, debug_verbose: reset_condensed_events_job_debug_verbose )
    return job_finished unless hostname_allowed?
    log( event: "reset condensed events job", hostname_allowed: hostname_allowed? )
    is_quiet?
    ::AnalyticsHelper.drop_condensed_event_downloads
    job_msg_queue << "Done dropping condensed events at #{DateTime.now}" 
    ::AnalyticsHelper.initialize_condensed_event_downloads
    job_msg_queue << "Done initializing condensed events at #{DateTime.now}"

    job_finished
    job_msg_queue << "Finished processing at #{DateTime.now}"
    email_results
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise
  end
  
end
