# frozen_string_literal: true

class GlobusStatusReportJob < ::Deepblue::DeepblueJob

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

globus_status_report_job:
  # Run once a day, 5 minutes after six pm (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H D
  cron: '5 18 * * *'
  class: GlobusStatusReportJob
  queue: scheduler
  description: Globus status report job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    quiet: true
    subscription_service_id: globus_status_report_job
    user_email:
      - 'fritx@umich.edu'

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  def perform( *args )
    initialize_options_from( *args, debug_verbose: ::Deepblue::JobTaskHelper.globus_status_report_job_debug_verbose )
    log( event: "globus status report job", hostname_allowed: hostname_allowed? )
    is_quiet?
    return job_finished unless by_request_only? && from_dashboard.present?
    return job_finished unless hostname_allowed?
    report = ::Deepblue::GlobusIntegrationService.globus_status_report( msg_handler: msg_handler,
                                                                        quiet: is_quiet?,
                                                                        debug_verbose: debug_verbose )
    if report.out.present?
      event = "globus status report job"
      email_all_targets( task_name: "globus status report",
                         event: event,
                         body: report.out,
                         content_type: ::Deepblue::EmailHelper::TEXT_HTML )
    end
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise
  end

end
