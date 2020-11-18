# frozen_string_literal: true

require_relative '../services/deepblue/works_reporter'

class UpdateCondensedEventsJob < ::Hyrax::ApplicationJob

  UPDATE_CONDENSED_EVENTS_JOB_DEBUG_VERBOSE = ::Deepblue::JobTaskHelper.update_condensed_events_job_debug_verbose

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


  include JobHelper
  queue_as :scheduler

  attr_accessor :hostname, :hostnames, :options, :quiet, :verbose

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if UPDATE_CONDENSED_EVENTS_JOB_DEBUG_VERBOSE
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "update condensed events job" )
    ::Deepblue::JobTaskHelper.has_options( *args, job: self, debug_verbose: UPDATE_CONDENSED_EVENTS_JOB_DEBUG_VERBOSE )
    ::Deepblue::JobTaskHelper.is_quiet( job: self, debug_verbose: UPDATE_CONDENSED_EVENTS_JOB_DEBUG_VERBOSE  )
    return unless ::Deepblue::JobTaskHelper.hostname_allowed( job: self, debug_verbose: UPDATE_CONDENSED_EVENTS_JOB_DEBUG_VERBOSE )
    ::AnalyticsHelper.update_current_month_condensed_events
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
