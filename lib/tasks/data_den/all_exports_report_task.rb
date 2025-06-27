# frozen_string_literal: true

require_relative './abstract_export_task'
require_relative './reexport_report_task'
require_relative './export_report_task'

module DataDen

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

dataden_export_report:
  # Run Monday and Wednesday at 10 or 11 AM (depending on DST)
  # Note: all parameters are set in the rake task job
  #      M  H D Mo WDay
  cron: '36 5 * * *'
  class: RakeTaskJob
  queue: scheduler
  description: Run rake task dataden:all_exports_report
  args:
    by_request_only: false
    hostnames:
       - 'deepblue.lib.umich.edu'
    job_delay: 0
    subscription_service_id: dataden_export_report
    rake_task: "data_den:all_exports_report"

END_OF_SCHEDULER_ENTRY

  class AllExportsReportTask < ::DataDen::AbstractExportTask

    mattr_accessor :all_export_report_task_debug_verbose, default: false

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @test_mode = true
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "All DataDen exports on %hostname% as of %now%"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
    end

    def run
      debug_verbose
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Reexports (modified since previous export):"
      task = ReexportReportTask.new( msg_handler: msg_handler, options: { 'email_results' => false } )
      task.run
      msg_handler.msg_verbose "New Exports:"
      task = ExportReportTask.new( msg_handler: msg_handler, options: { 'email_results' => false } )
      task.run
      run_email_targets( subject: @email_subject, event: 'AllExportsReport' )
      msg_handler.msg_verbose "Finished report."
    end

  end

end
