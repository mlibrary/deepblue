# frozen_string_literal: true

module Deepblue

  require_relative '../../../lib/tasks/task_helper'

  # rubocop:disable Rails/Output
  class AbstractService

    DEFAULT_QUIET = false
    DEFAULT_TO_CONSOLE = false
    DEFAULT_VERBOSE = false

    attr_reader :options

    attr_accessor :verbose, :to_console, :logger, :options_error, :quiet, :rake_task

    def initialize( rake_task: false, options: {} )
      @rake_task = rake_task
      @options = task_options_parse options
      @options_error = @options[ :error ] if @options.key?( :error )
      @options_error = @options[ 'error' ] if @options.key?( 'error' )
      if @options_error.present?
        @logger = Rails.logger
        @quiet = false
        console_puts "WARNING: options error #{@options['error']}"
        console_puts "options=#{options}" if @options.key? 'error'
        console_puts "@options=#{@options}" if @options.key? 'error'
      end
      @quiet = task_options_value( key: 'quiet', default_value: DEFAULT_QUIET )
      if @quiet
        @to_console = false
        @verbose = false
      else
        @to_console = task_options_value( key: 'to_console', default_value: DEFAULT_TO_CONSOLE )
        @verbose = task_options_value( key: 'verbose', default_value: DEFAULT_VERBOSE )
      end
      @logger = task_options_value( key: 'logger', default_value: nil ) if @options_error.blank?
      console_puts "@verbose=#{@verbose}" if @verbose
    end

    def console_print( msg = "" )
      return if @quiet
      if rake_task
        print msg
        STDOUT.flush
      else
        logger.info msg
      end
    end

    def console_puts( msg = "" )
      return if @quiet
      if rake_task
        puts msg
      else
        logger.info msg
      end
    end

    def logger
      @logger ||= logger_initialize
    end

    def task_msg( msg )
      return if @quiet
      logger.debug msg
      console_puts msg if @to_console
    end

    def task_options_value( key:, default_value: nil, verbose: false )
      options = @options
      return default_value if options.blank?
      return default_value unless options.key? key
      # if [true, false].include? default_value
      #   return options[key].to_bool
      # end
      console_puts "set key #{key} to #{options[key]}" if verbose
      return options[key]
    end

    def task_options_parse( options_str )
      return options_str if options_str.is_a? Hash
      return {} if options_str.blank?
      ActiveSupport::JSON.decode options_str
    rescue ActiveSupport::JSON.parse_error => e
      return { 'error': e, 'options_str': options_str }
    end

    protected

      def logger_initialize
        Rails.logger
      end

  end
  # rubocop:enable Rails/Output

end
