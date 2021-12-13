# frozen_string_literal: true

class GlobusErrorsReportJob < ::Deepblue::DeepblueJob

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

globus_errors_report_job:
  # Run once a day, 5 minutes after six pm (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H D
  cron: '5 18 * * *'
  class: GlobusErrorsReportJob
  queue: scheduler
  description: Globus error report job.
  args:
    by_request_only: false
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    quiet: true
    subscription_service_id: globus_errors_report_job
    user_email:
      - 'fritx@umich.edu'

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  def perform( *args )
    initialize_options_from( *args, debug_verbose: ::Deepblue::JobTaskHelper.globus_errors_report_job_debug_verbose )
    log( event: "globus errors report job", hostname_allowed: hostname_allowed? )
    is_quiet?
    return job_finished unless by_request_only? && from_dashboard.present?
    return job_finished unless hostname_allowed?
    report = ::Deepblue::GlobusIntegrationService.globus_errors_report( quiet: is_quiet?, debug_verbose: debug_verbose )
    if report.out.present? && !suppress_if_quiet
      event = "globus errors report job"
      email_all_targets( task_name: "globus errors report", event: event, body: report.out, content_type: 'text/html' )
    end
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise
  end

  def suppress_if_quiet
    false
  end

end
