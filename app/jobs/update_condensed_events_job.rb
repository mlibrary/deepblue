# frozen_string_literal: true

class UpdateCondensedEventsJob < ::Hyrax::ApplicationJob

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


  include JobHelper # see JobHelper for :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as :scheduler

  attr_accessor :hostnames, :options, :quiet, :verbose

  def perform( *args )
    timestamp_begin
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if update_condensed_events_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "update condensed events job" )
    ::Deepblue::JobTaskHelper.has_options( *args, job: self, debug_verbose: update_condensed_events_job_debug_verbose )
    ::Deepblue::JobTaskHelper.is_quiet( job: self, debug_verbose: update_condensed_events_job_debug_verbose  )
    return unless ::Deepblue::JobTaskHelper.hostname_allowed( job: self, debug_verbose: update_condensed_events_job_debug_verbose )
    ::AnalyticsHelper.update_current_month_condensed_events
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
