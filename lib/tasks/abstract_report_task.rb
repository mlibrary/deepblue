# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_task'

  class AbstractReportTask < AbstractTask

    DEFAULT_REPORT_FORMAT = 'report.yml'

    attr_accessor :report_format

    def initialize( options: {} )
      super( options: options )
    end

    def initialize_input
      task_options_value( key: 'report_format', default_value: DEFAULT_REPORT_FORMAT )
    end

    def run
      puts "Reading report format from #{report_format}" if verbose
      write_report
    end

    # overwrite this with something interesting
    def write_report

    end

  end

end
