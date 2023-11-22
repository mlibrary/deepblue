# frozen_string_literal: true

module Deepblue

  class AbstractReportTask < AbstractTask

    DEFAULT_REPORT_FORMAT = 'report.yml' unless const_defined? :DEFAULT_REPORT_FORMAT

    attr_accessor :report_format

    def initialize( options: {}, msg_handler: nil )
      super( options: options, msg_handler: msg_handler )
    end

    def initialize_input
      task_options_value( key: 'report_format', default_value: DEFAULT_REPORT_FORMAT )
    end

    # overwrite this with something interesting
    def email_report

    end

    def expand_path_partials( path )
      return path unless path.present?
      path = ::Deepblue::ReportHelper.expand_path_partials( path )
      return path
    end

    def run
      puts "Reading report format from #{report_format}" if verbose
      write_report
      email_report
    end

    # overwrite this with something interesting
    def write_report

    end

  end

end
