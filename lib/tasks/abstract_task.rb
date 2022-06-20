# frozen_string_literal: true

require_relative './task_logger'
require_relative './task_helper'

module Deepblue

  #require 'tasks/task_logger'

  # rubocop:disable Rails/Output
  class AbstractTask

    DEFAULT_TO_CONSOLE = true unless const_defined? :DEFAULT_TO_CONSOLE
    DEFAULT_VERBOSE = false unless const_defined? :DEFAULT_VERBOSE

    attr_accessor :logger
    attr_accessor :msg_queue
    attr_accessor :msg_handler
    attr_reader   :options

    attr_accessor :debug_verbose
    alias :debug_verbose? :debug_verbose

    attr_accessor :to_console
    alias :to_console? :to_console

    attr_accessor :verbose
    alias :verbose? :verbose

    def initialize( options: {}, msg_handler: nil, msg_queue: nil, debug_verbose: false )
      @debug_verbose = debug_verbose
      @msg_handler = msg_handler
      @msg_queue = msg_queue
      @options = TaskHelper.task_options_parse options
      @options = @options.with_indifferent_access if @options.respond_to? :with_indifferent_access
      @to_console = TaskHelper.task_options_value( @options, key: 'to_console', default_value: DEFAULT_TO_CONSOLE )
      @verbose = TaskHelper.task_options_value( @options, key: 'verbose', default_value: DEFAULT_VERBOSE )
      @msg_handler ||= MessageHandler.new( msg_queue: @msg_queue,
                                           to_console: @to_console,
                                           verbose: @verbose,
                                           debug_verbose: @debug_verbose )
      report_puts "@verbose=#{@verbose}" if @verbose
      if  @options.key?( :error )
        report_puts "WARNING: options error #{@options[:error]}"
        report_puts "options=#{options}"
      elsif @options.key?( 'error' )
        report_puts "WARNING: options error #{@options['error']}"
        report_puts "options=#{options}"
      end
    end

    def logger
      @logger ||= logger_initialize
    end

    # def task_msg( msg )
    #   # logger.debug msg
    #   # report_puts msg if @to_console
    #   @msg_handler.msg_debug msg
    # end

    def report_puts( str = '' )
      msg_handler.msg str
      # if msg_queue
      #   msg_queue << str
      # else
      #   puts str
      # end
    end

    def set_quiet( quiet: )
      if quiet
        verbose = true
      else
        verbose = false
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
