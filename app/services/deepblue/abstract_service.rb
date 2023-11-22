# frozen_string_literal: true

module Deepblue

  # rubocop:disable Rails/Output
  class AbstractService

    # DEFAULT_QUIET = false unless const_defined? :DEFAULT_QUIET
    DEFAULT_TO_CONSOLE = false unless const_defined? :DEFAULT_TO_CONSOLE
    # DEFAULT_VERBOSE = false unless const_defined? :DEFAULT_VERBOSE

    attr_reader :options

    attr_accessor :msg_handler
    attr_accessor :options_error
    attr_accessor :subscription_service_id

    attr_writer :logger

    def initialize( msg_handler:, options: {} )
      @msg_handler = msg_handler
      @msg_handler ||= MessageHandler.msg_handler_for_task( options: @options )
      @options = task_options_parse options
      if OptionsHelper.error? @options
        @options_error = @options[:error]
        @msg_handler.msg_warn "options error #{@options[:error]}"
      else
        @msg_handler.verbose = task_options_value( key: 'verbose', default_value: @msg_handler.verbose )
        @msg_handler.quiet = task_options_value( key: 'quiet', default_value: @msg_handler.quiet )
      end
      @subscription_service_id = task_options_value( key: 'subscription_service_id' )
    end

    def debug_verbose
      @msg_handler.debug_verbose
    end

    def logger
      @logger ||= logger_initialize
    end

    def quiet
      @msg_handler.quiet
    end

    def task_options_value( key:, default_value: nil )
      OptionsHelper.value( @options, key: key, default_value: default_value, msg_handler: @msg_handler )
    end

    def task_options_parse( options_str )
      OptionsHelper.parse options_str
    end

    def to_datetime( date:, format: nil, raise_errors: true, msg_postfix: '' )
      ReportHelper.to_datetime( date: date,
                                format: format,
                                msg_handler: @msg_handler,
                                raise_errors: raise_errors,
                                msg_postfix: msg_postfix )
    end

    def verbose
      @msg_handler.verbose
    end

    protected

      def logger_initialize
        Rails.logger
      end

  end
  # rubocop:enable Rails/Output

end
