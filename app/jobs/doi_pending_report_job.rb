# frozen_string_literal: true

class DoiPendingReportJob < ::Deepblue::DeepblueJob

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

doi_pending_report_job:
  # Run once on Saturdays at two am (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H D
  cron: '0 6 * * 6'
  class: DoiPendingReportJob
  queue: scheduler
  description: DOI pending report job.
  args:
    by_request_only: true
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    quiet: true
    subscription_service_id: doi_pending_report_job
    user_email:
      - 'fritx@umich.edu'

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  def perform( *args )
    initialize_options_from( args: args, debug_verbose: ::Deepblue::JobTaskHelper.doi_pending_report_job_debug_verbose )
    log( event: "globus errors report job", hostname_allowed: hostname_allowed? )
    return job_finished unless by_request_only? && from_dashboard.present?
    return job_finished unless hostname_allowed?
    reporter = ::Deepblue::DoiPendingReporter.new( msg_handler: msg_handler,
                                                   debug_verbose: debug_verbose,
                                                   options: options )
    reporter.run
    if reporter.out.present? && !suppress_if_quiet
      event = "doi pending report job"
      email_all_targets( task_name: "doi pending report",
                         event: event,
                         body: reporter.out,
                         content_type: ::Deepblue::EmailHelper::TEXT_HTML )
    end
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

  def suppress_if_quiet
    false
  end

end
