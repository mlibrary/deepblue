# frozen_string_literal: true

require_relative './abstract_report_task'
require_relative '../../../app/services/aptrust/aptrust_report_status'

module Aptrust

  class ReportAllAptrustStatusTask < ::Aptrust::AbstractReportTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Starting..."
      run_report
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'Aptrust::ReportAllAptrustStatusTask', event: 'ReportAllAptrustStatusTask' )
    end

    def run_report_file_init
      return if @report_file.present?
      @report_file = '%date%.aptrust_all_aptrust_statuses.csv'
      @report_file = File.join report_dir, @report_file
      @report_file = ::Deepblue::ReportHelper.expand_path_partials @report_file
      @report_file = File.absolute_path @report_file
    end

    def run_report
      run_report_file_init
      msg_handler.msg_verbose "report_file=#{report_file}"
      reporter = AptrustReportStatus.new( msg_handler:    msg_handler,
                                          aptrust_config: aptrust_config,
                                          target_file:    report_file,
                                          debug_verbose:  debug_verbose )
      reporter.run
    end

  end

end
