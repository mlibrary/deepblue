# frozen_string_literal: true

module Deepblue

  require_relative '../../../lib/tasks/task_helper'

  # rubocop:disable Rails/Output
  class AbstractService

    DEFAULT_QUIET = false unless const_defined? :DEFAULT_QUIET
    DEFAULT_TO_CONSOLE = false unless const_defined? :DEFAULT_TO_CONSOLE
    DEFAULT_VERBOSE = false unless const_defined? :DEFAULT_VERBOSE

    attr_reader :options

    attr_accessor :msg_handler,
                  :options_error,
                  :quiet,
                  :subscription_service_id,
                  :verbose

    attr_writer :logger

    def initialize( msg_handler:, options: {} )
      @msg_handler = msg_handler
      @options = task_options_parse options
      if OptionsHelper.error? @options
        @options_error = @options[:error]
        @quiet = false
        msg_handler.msg_warn "options error #{@options[:error]}"
      else
        @quiet = task_options_value( key: 'quiet', default_value: DEFAULT_QUIET )
      end
      if @quiet
        @verbose = false
      else
        @verbose = task_options_value( key: 'verbose', default_value: DEFAULT_VERBOSE )
      end
      @msg_handler.quiet = @quiet
      @subscription_service_id = task_options_value( key: 'subscription_service_id' )
      msg_handler.msg_verbose "@verbose=#{@verbose}"
    end

    def logger
      @logger ||= logger_initialize
    end

    def task_options_value( key:, default_value: nil )
      OptionsHelper.value( @options, key: key, default_value: default_value, msg_handler: msg_handler )
    end

    def task_options_parse( options_str )
      OptionsHelper.parse options_str
    end

    def to_datetime( date:, format: nil, raise_errors: true, msg_postfix: '' )
      ReportHelper.to_datetime( date: date,
                                format: format,
                                msg_handler: msg_handler,
                                raise_errors: raise_errors,
                                msg_postfix: msg_postfix )
    end

    protected

      def logger_initialize
        Rails.logger
      end

  end
  # rubocop:enable Rails/Output

end
