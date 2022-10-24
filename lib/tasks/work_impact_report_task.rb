# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_report_task'
  require_relative '../../app/services/deepblue/work_impact_reporter'

  class WorkImpactReportTask < AbstractReportTask

    attr_accessor :prefix, :quiet, :report_dir, :report_file

    def initialize( options: {}, msg_handler: nil )
      super( options: options, msg_handler: msg_handler )
    end

    def run
      @quiet = task_options_value( key: 'quiet', default_value: DEFAULT_REPORT_QUIET )
      set_quiet( quiet: @quiet )
      reporter = WorkImpactReporter.new( msg_handler: msg_handler, options: options )
      reporter.run
    end

  end

end
