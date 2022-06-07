# frozen_string_literal: true

require_relative "../../app/helpers/deepblue/export_files_helper"

class ExportLogFilesJob < ::Deepblue::DeepblueJob

  mattr_accessor :export_log_files_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.export_log_files_job_debug_verbose

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

export_log_files_job:
  # Run once a week at midnight
  #      M H D
  # cron: '*/5 * * * *'
  cron: '0 5 * * 0'
  class: ExportLogFilesJob
  queue: default
  description: Export log files to deepbluedata-prep job.
  args:
    by_request_only: true
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    verbose: false

END_OF_SCHEDULER_ENTRY

  queue_as :default

  def perform( *args )
    debug_verbose = export_log_files_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if debug_verbose
    initialize_options_from( *args, debug_verbose: debug_verbose )
    log( event: "export log files job", hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    ::Deepblue::ExportFilesHelper.export_log_files( msg_queue: msg_queue, verbose: job_msg_queue )
    email_all_targets( task_name: "export log files",
                       event: "export log files" ,
                       body: job_msg_queue.join("\n"),
                       debug_verbose: export_log_files_job_debug_verbose )
    job_finished

  rescue Exception => e # rubocop:disable Lint/RescueException
    email_all_targets( task_name: "export log files",
                       event: "export log files" ,
                       body: job_msg_queue.join("\n") + e.message + "\n" + e.backtrace.join("\n"),
                       debug_verbose: export_log_files_job_debug_verbose )
    job_status_register( exception: e, args: { user_email: user_email } )
    raise e

  end

end
