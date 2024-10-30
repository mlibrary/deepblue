# frozen_string_literal: true

require_relative './abstract_report_task'
require_relative '../../../app/services/aptrust/aptrust_report_status'

module Aptrust

  class ReportAllAptrustStatusTask < ::Aptrust::AbstractReportTask

    def initialize( msg_handler: nil, options: {} )

      # bundle exec rake aptrust:report_all_aptrust_status['{"verbose":true\,
      # "report_dir":"/deepbluedata-prep/_DBD_Reports/"\,
      # "report_file":"%date%.%hostname%.aptrust_all_work_statuses.csv"\,
      # "email_targets":"fritx@umich.edu"\,
      # "email_subject":"Aptrust status report on %hostname% finished %now%"}']

      super( msg_handler: msg_handler, options: options )
      if msg_handler.nil?
        @verbose = option_value( key: 'verbose', default_value: true )
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      hostname = Rails.configuration.hostname
      @msg_handler.msg_debug "hostname=#{hostname}"
      if 'deepblue.local' == hostname && @report_dir == './data'
        @report_dir = option_value( key: 'report_dir', default_value: './data' )
        @report_file = report_file_init( default_value: "%date%.%hostname%.aptrust_all_work_statuses.csv" )
      end
      # @test_mode = option_value( key: 'test_mode', default_value: false )
      if @email_targets.nil? || @email_targets.empty?
        @email_targets = option_email_targets( default_value: "fritx@umich.edu" )
      end
      @email_subject = option_value( key: 'email_subject',
                                     default_value: "Aptrust status report on %hostname% finished %now%" )
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
      @msg_handler.msg_debug "report_dir: #{@report_dir}"
      @msg_handler.msg_debug "report_file: #{@report_file}"
    end

    def run
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Starting..."
      run_report
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'Aptrust::ReportAllAptrustStatusTask',
                         event: 'ReportAllAptrustStatusTask',
                         debug_verbose: debug_verbose )
    end

    def run_report_file_init
      return if @report_file.present?
      @report_file = '%date%.aptrust_all_aptrust_statuses.csv'
      @report_file = File.join report_dir, @report_file
      @report_file = ::Deepblue::ReportHelper.expand_path_partials @report_file
      @report_file = File.absolute_path @report_file
      msg_handler.msg_debug( [ msg_handler.here, msg_handler.called_from,
                               "@report_file=#{@report_file}" ] )
    end

    def run_report
      run_report_file_init
      msg_handler.msg_verbose "report_file=#{report_file}"
      reporter = AptrustReportStatus.new( msg_handler:    msg_handler,
                                          aptrust_config: aptrust_config,
                                          target_file:    report_file,
                                          test_mode:      test_mode,
                                          debug_verbose:  debug_verbose )
      reporter.run
    end

  end

end
