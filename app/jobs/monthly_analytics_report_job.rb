# frozen_string_literal: true

require_relative '../services/deepblue/works_reporter'

class MonthlyAnalyticsReportJob < ::Deepblue::DeepblueJob

  mattr_accessor :monthly_analytics_report_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.monthly_analytics_report_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

monthly_analytics_report_job:
  # Run once a month on the 1st, twenty-five minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H D
  # cron: '*/5 * * * *'
  cron: '25 5 1 * *'
  class: MonthlyAnalyticsReportJob
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

  queue_as :scheduler

  attr_accessor :this_month

  def perform( *args )
    initialize_options_from( *args, debug_verbose: monthly_analytics_report_job_debug_verbose )
    log( event: "monthly analytics report job", hostname_allowed: hostname_allowed? )
    is_quiet?
    return job_finished unless hostname_allowed?
    this_month = job_options_value( options, key: 'this_month', default_value: debug_verbose )
    if this_month
      date_range = ::AnalyticsHelper.date_range_for_month_of( time: Time.now )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "date_range=#{date_range}",
                                             "" ] if monthly_analytics_report_job_debug_verbose
      ::AnalyticsHelper.monthly_analytics_report( date_range: date_range,
                                                  debug_verbose: monthly_analytics_report_job_debug_verbose )
    else
      ::AnalyticsHelper.monthly_analytics_report
    end
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise
  end

end
