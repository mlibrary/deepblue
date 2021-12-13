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

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if update_condensed_events_job_debug_verbose
    initialize_options_from( *args, debug_verbose: update_condensed_events_job_debug_verbose )
    return job_finished unless hostname_allowed?
    log( event: "update condensed events job", hostname_allowed: hostname_allowed? )
    is_quiet?
    ::AnalyticsHelper.update_current_month_condensed_events
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise
  end

end
