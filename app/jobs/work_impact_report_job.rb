# frozen_string_literal: true

require_relative '../services/deepblue/work_impact_reporter'

class WorkImpactReportJob < ::Deepblue::DeepblueJob

  mattr_accessor :work_impact_report_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.work_impact_report_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

work_impact_report_job_monthly:
  # Run once a day, five minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H D
  # cron: '*/5 * * * *'
  cron: '5 5 1 * *'
  class: WorkImpactReportJob
  queue: scheduler
  description: Work impact report job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    quiet: true
    report_file_prefix: '%date%.%hostname%.work_impact_report'
    report_dir: '/deepbluedata-prep/reports'
    subscription_service_id: work_impact_report_job

END_OF_SCHEDULER_ENTRY

  queue_as :default

  EVENT = "work impact report"

  def perform( *args )
    initialize_options_from( *args, debug_verbose: work_impact_report_job_debug_verbose )
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: EVENT, hostname_allowed: hostname_allowed? )
    return unless hostname_allowed?
    reporter = ::Deepblue::WorkImpactReporter.new( msg_handler: msg_handler, options: options )
    reporter.run
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, rails_log: true, args: args )
    email_failure( task_name: task_name, exception: e, event: event_name )
    raise e
  end

end
