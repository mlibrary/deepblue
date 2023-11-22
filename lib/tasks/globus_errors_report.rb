# frozen_string_literal: true

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_report_task'
  require_relative '../../app/services/deepblue/globus_integration_service'

  class GlobusErrorsReport < AbstractReportTask

    DEFAULT_REPORT_DIR = nil unless const_defined? :DEFAULT_REPORT_DIR
    DEFAULT_REPORT_FILE_PREFIX = nil unless const_defined? :DEFAULT_REPORT_FILE_PREFIX
    DEFAULT_REPORT_QUIET = true unless const_defined? :DEFAULT_REPORT_QUIET

    attr_accessor :options
    attr_accessor :prefix, :quiet, :report_dir, :report_file

    def initialize( msg_handler:, options: )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      # puts "ARGV=#{ARGV}"
      # puts "options=#{options}"
      @quiet = task_options_value( key: 'quiet', default_value: DEFAULT_REPORT_QUIET )
      @verbose = false if quiet
      reporter = GlobusService.globus_status_report( msg_handler: msg_handler, errors_report: true )
      report = reporter.out
      return unless report.present?
      @report_dir = task_options_value( key: 'report_dir', default_value: DEFAULT_REPORT_DIR )
      return unless @report_dir.present?
      @prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      @prefix = "#{Time.now.strftime('%Y%m%d')}_globus_errors_report" if @prefix.nil?
      @prefix = expand_path_partials( prefix )
      @report_dir = expand_path_partials( report_dir )
      @report_file = Pathname.new( report_dir ).join "#{prefix}.txt"
      File.open( report_file, 'w' ) { |f| f << report << "\n" }
    end

  end

end
