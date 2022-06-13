# frozen_string_literal: true

require_relative './abstract_task'

module Deepblue

  #require 'tasks/abstract_task'

  class AbstractReportTask < ::Deepblue::AbstractTask

    DEFAULT_REPORT_FORMAT = 'report.yml' unless const_defined? :DEFAULT_REPORT_FORMAT

    attr_accessor :report_format

    def initialize( options: {}, msg_handler: nil, msg_queue: nil, debug_verbose: false )
      super( options: options, msg_handler: msg_handler, msg_queue: msg_queue, debug_verbose: debug_verbose )
    end

    def initialize_input
      task_options_value( key: 'report_format', default_value: DEFAULT_REPORT_FORMAT )
    end

    def expand_path_partials( path )
      return path unless path.present?
      now = Time.now
      path = path.gsub( /\%date\%/, "#{now.strftime('%Y%m%d')}" )
      path = path.gsub( /\%time\%/, "#{now.strftime('%H%M%S')}" )
      path = path.gsub( /\%timestamp\%/, "#{now.strftime('%Y%m%d%H%M%S')}" )
      path = path.gsub( /\%hostname\%/, "#{Rails.configuration.hostname}" )
      return path
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
