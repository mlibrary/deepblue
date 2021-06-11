# frozen_string_literal: true

require_relative './task_logger'
require_relative './task_helper'

module Deepblue

  #require 'tasks/task_logger'

  # rubocop:disable Rails/Output
  class AbstractTask

    DEFAULT_TO_CONSOLE = true

    DEFAULT_VERBOSE = false

    attr_accessor :msg_queue
    attr_reader :options
    attr_accessor :verbose, :to_console, :logger

    def initialize( options: {}, msg_queue: nil )
      @msg_queue = msg_queue
      @options = TaskHelper.task_options_parse options
      if  @options.key?( :error )
        report_puts "WARNING: options error #{@options[:error]}"
        report_puts "options=#{options}"
      end
      if @options.key?( 'error' )
        report_puts "WARNING: options error #{@options['error']}"
        report_puts "options=#{options}"
      end
      @to_console = TaskHelper.task_options_value( @options, key: 'to_console', default_value: DEFAULT_TO_CONSOLE )
      @verbose = TaskHelper.task_options_value( @options, key: 'verbose', default_value: DEFAULT_VERBOSE )
      report_puts "@verbose=#{@verbose}" if @verbose
    end

    def logger
      @logger ||= logger_initialize
    end

    def task_msg( msg )
      logger.debug msg
      report_puts msg if @to_console
    end

    def report_puts( str = '' )
      if msg_queue
        msg_queue << str
      else
        puts str
      end
    end

    def task_options_value( key:, default_value: nil, verbose: false )
      TaskHelper.task_options_value( @options, key: key, default_value: default_value, verbose: verbose )
    end

    protected

      def logger_initialize
        # TODO: add some flags to the input yml file for log level and Rails logging integration
        TaskHelper.logger_new
      end

  end
  # rubocop:enable Rails/Output

end
