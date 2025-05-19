# frozen_string_literal: true

require_relative './abstract_report_task'
require_relative '../../../app/models/file_export'
require_relative '../../../app/services/file_sys_export_c'
require_relative '../../../app/services/file_sys_export_integration_service'

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

  class FileExportReportTask < ::DataDen::AbstractReportTask

    mattr_accessor :file_export_report_task_debug_verbose, default: true

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @event = "FileSet Report"
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @test_mode = true
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "All DataDen file exports on %hostname% as of %now%"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
    end

    def report_file_init( default_value: "%date%.%hostname%.file_export_report.csv" )
      super( default_value: default_value )
    end

    def run_report
      records = FileExport.all
      csv_out << FileExport.csv_row( nil )
      records.each do |record|
        next unless FileSysExportIntegrationService.data_den_export_type == record.export_type
        csv_out << FileExport.csv_row( record )
      end
    end

  end

end
