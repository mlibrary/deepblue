# frozen_string_literal: true

module Deepblue

  #require 'tasks/task_logger'

  # rubocop:disable Rails/Output
  class AbstractTask

    # DEFAULT_TO_CONSOLE = true unless const_defined? :DEFAULT_TO_CONSOLE
    # DEFAULT_VERBOSE = false unless const_defined? :DEFAULT_VERBOSE

    attr_accessor :logger
    attr_accessor :msg_handler
    attr_reader   :options

    delegate :debug_verbose, :debug_verbose=, to: :msg_handler
    alias :debug_verbose? :debug_verbose
    delegate :msg_queue, :msg_queue=, to: :msg_handler
    delegate :quiet, :quiet=, to: :msg_handler
    alias :quiet? :quiet
    delegate :to_console, :to_console=, to: :msg_handler
    alias :to_console? :to_console
    delegate :verbose, :verbose=, to: :msg_handler
    alias :verbose? :verbose

    def initialize( msg_handler: nil, options: {} )
      @options = TaskHelper.task_options_parse options
      @options = @options.with_indifferent_access if @options.respond_to? :with_indifferent_access
      @msg_handler = msg_handler
      @msg_handler ||= MessageHandler.msg_handler_for_task( options: @options )
      report_puts "verbose=#{@msg_handler.verbose}" if @msg_handler.verbose
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

    def report_puts( str = '' )
      msg_handler.msg str
    end

    def set_quiet( quiet: )
      if quiet
        verbose = true
      else
        verbose = false
      end
    end

    def task_options_value( key:, default_value: nil )
      TaskHelper.task_options_value( @options, key: key, default_value: default_value, msg_handler: msg_handler )
    end

    protected

      def logger_initialize
        # TODO: add some flags to the input yml file for log level and Rails logging integration
        TaskHelper.logger_new
      end

  end
  # rubocop:enable Rails/Output

end
