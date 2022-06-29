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

  EVENT = "export log files"

  queue_as :default

  def perform( *args )
    initialize_options_from( *args, debug_verbose: export_log_files_job_debug_verbose )
    log( event: EVENT, hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    ::Deepblue::ExportFilesHelper.export_log_files( msg_handler: msg_handler,
                                                    debug_verbose: msg_handler.debug_verbose )
    email_all_targets( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
