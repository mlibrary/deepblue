# frozen_string_literal: true

class UpdateCondensedEventsJob < ::Deepblue::DeepblueJob

  mattr_accessor :update_condensed_events_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.update_condensed_events_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

update_condensed_events_job_daily:
  # Run once a day, twenty-five minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H D
  # cron: '*/5 * * * *'
  cron: '25 5 * * *'
  class: UpdateCondensedEventsJob
  queue: scheduler
  description: Update the condensed events job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    quiet: true

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  EVENT = 'update condensed events'

  def perform( *args )
    initialize_options_from( args: args, debug_verbose: update_condensed_events_job_debug_verbose )
    return job_finished unless hostname_allowed?
    log( event: "update condensed events job", hostname_allowed: hostname_allowed? )
    ::AnalyticsHelper.update_current_month_condensed_events( msg_handler: msg_handler )
    ::AnalyticsHelper.updated_condensed_event_work_downloads( msg_handler: msg_handler )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
