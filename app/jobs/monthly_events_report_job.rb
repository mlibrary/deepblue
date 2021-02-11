# frozen_string_literal: true

require_relative '../services/deepblue/works_reporter'

class MonthlyEventsReportJob < ::Hyrax::ApplicationJob

  MONTHLY_EVENTS_REPORT_JOB_DEBUG_VERBOSE = ::Deepblue::JobTaskHelper.monthly_events_report_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

monthly_events_report_job:
  # Run once a month on the 1st, twenty-five minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H D
  # cron: '*/5 * * * *'
  cron: '25 5 1 * *'
  class: MonthlyEventsReportJob
  queue: scheduler
  description: Monthly events report job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    quiet: true
    this_month: false

END_OF_SCHEDULER_ENTRY


  include JobHelper # see JobHelper for :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as :scheduler

  attr_accessor :hostnames, :options, :quiet, :this_month, :verbose

  def perform( *args )
    timestamp_begin
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if MONTHLY_EVENTS_REPORT_JOB_DEBUG_VERBOSE
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "update condensed events job" )
    ::Deepblue::JobTaskHelper.has_options( *args, job: self, debug_verbose: MONTHLY_EVENTS_REPORT_JOB_DEBUG_VERBOSE )
    ::Deepblue::JobTaskHelper.is_quiet( job: self, debug_verbose: MONTHLY_EVENTS_REPORT_JOB_DEBUG_VERBOSE  )
    return unless ::Deepblue::JobTaskHelper.hostname_allowed( job: self, debug_verbose: MONTHLY_EVENTS_REPORT_JOB_DEBUG_VERBOSE )
    this_month = job_options_value( options, key: 'this_month', default_value: false )
    if this_month
      date_range = ::AnalyticsHelper.date_range_for_month_of( time: Time.now )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "date_range=#{date_range}",
                                             "" ] if MONTHLY_EVENTS_REPORT_JOB_DEBUG_VERBOSE
      ::AnalyticsHelper.monthly_events_report( date_range: date_range )
    else
      ::AnalyticsHelper.monthly_events_report
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
