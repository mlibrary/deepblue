# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_report_task'
  require_relative '../../app/services/deepblue/doi_pending_reporter'

  class DoiPendingReportTask < AbstractReportTask

    DEFAULT_REPORT_DIR = nil unless const_defined? :DEFAULT_REPORT_DIR
    DEFAULT_REPORT_FILE_PREFIX = nil unless const_defined? :DEFAULT_REPORT_FILE_PREFIX
    DEFAULT_REPORT_QUIET = true unless const_defined? :DEFAULT_REPORT_QUIET

    attr_accessor :prefix, :quiet, :report_dir, :report_file

    def initialize( options: {}, msg_handler: nil, msg_queue: nil, debug_verbose: false )
      super( options: options, msg_handler: msg_handler, msg_queue: msg_queue, debug_verbose: debug_verbose )
    end

    def run
      # puts "ARGV=#{ARGV}"
      # puts "options=#{options}"
      @quiet = task_options_value( key: 'quiet', default_value: DEFAULT_REPORT_QUIET )
      @verbose = false if quiet
      reporter = DoiPendingReporter.new( debug_verbose: verbose, msg_handler: msg_handler )
      reporter.run
      report = reporter.out
      return unless report.present?
      @report_dir = task_options_value( key: 'report_dir', default_value: DEFAULT_REPORT_DIR )
      msg_handler.msg "Report dir: '#{@report_dir}' not found" unless @report_dir.present?
      return unless @report_dir.present?
      @prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      @prefix = "#{Time.now.strftime('%Y%m%d')}_doi_pending_report" if @prefix.nil?
      @prefix = expand_path_partials( prefix )
      @report_dir = expand_path_partials( report_dir )
      @report_file = Pathname.new( report_dir ).join "#{prefix}.txt"
      File.open( report_file, 'w' ) { |f| f << report << "\n" }
      msg_handler.msg "Report file: #{@report_file}"
    end

  end

end
