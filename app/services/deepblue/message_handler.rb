# frozen_string_literal: true

module Deepblue

  class MessageHandler

    DEFAULT_DEBUG_VERBOSE = false
    DEFAULT_MSG_PREFIX = ''.freeze
    DEFAULT_TO_CONSOLE = false
    DEFAULT_VERBOSE = false

    LOG_DEBUG = 'debug'.freeze
    LOG_ERROR = 'error'.freeze
    LOG_INFO  = 'info'.freeze
    LOG_NONE  = nil
    LOG_WARN  = 'warn'.freeze

    PREFIX_DEBUG = 'DEBUG: '.freeze
    PREFIX_ERROR = 'ERROR: '.freeze
    PREFIX_INFO  = 'INFO: '.freeze
    PREFIX_NONE  = ''.freeze
    PREFIX_WARN  = 'WARNING: '.freeze

    def self.msg_handler_for( task:,
                              debug_verbose: DEFAULT_DEBUG_VERBOSE,
                              msg_prefix: DEFAULT_MSG_PREFIX,
                              msg_queue: [],
                              to_console: DEFAULT_TO_CONSOLE,
                              verbose: DEFAULT_VERBOSE )

      if task
        MessageHandler.new( debug_verbose: debug_verbose,
                            msg_prefix: msg_prefix,
                            msg_queue: nil,
                            to_console: true,
                            verbose: verbose )
      else
        MessageHandler.new( debug_verbose: debug_verbose,
                            msg_prefix: msg_prefix,
                            msg_queue: msg_queue,
                            to_console: to_console,
                            verbose: verbose )
      end
    end

    # if set to quiet, then all messages except warnings and errors will be ignored
    attr_accessor :quiet

    attr_accessor :debug_verbose, :msg_prefix, :msg_queue, :to_console, :verbose
    attr_writer :logger
    attr_accessor :line_buffer

    def initialize( debug_verbose: DEFAULT_DEBUG_VERBOSE,
                    msg_prefix: DEFAULT_MSG_PREFIX,
                    msg_queue: [],
                    to_console: DEFAULT_TO_CONSOLE,
                    verbose: DEFAULT_VERBOSE )

      @debug_verbose = debug_verbose
      @msg_prefix = msg_prefix
      @msg_prefix ||= PREFIX_NONE
      @msg_queue = msg_queue
      @quiet = false
      @to_console = to_console
      @verbose = verbose
      @line_buffer = ''
    end

    # Provide the same functionality as the LoggingHelper.bold_debug, but override bold_puts parameter
    # with the MessageHandler's to_console flag, and use the MessageHandler's logger, which defaults
    # to Rails.logger
    def self.bold_debug( msg = nil,
                         bold_puts: @to_console,
                         label: nil,
                         key_value_lines: true,
                         add_stack_trace: false,
                         add_stack_trace_depth: 3,
                         lines: 1,
                         logger: nil, # defaults to the MessageHandler's logger
                         &block )

      logger ||= self.logger
      LoggingHelper.bold_debug( msg,
                                bold_puts: bold_puts,
                                label: label,
                                key_value_lines: key_value_lines,
                                add_stack_trace: add_stack_trace,
                                add_stack_trace_depth: add_stack_trace_depth,
                                lines: lines,
                                logger: logger,
                                &block )
    end

    # buffer up input messages then pre-pend the next msg with the buffer,
    # if the flush flag is true, and the message handler is only sending to the console, then print msg
    # directly to STDOUT and flush, then clear the buffer
    def buffer( msg, flush: true )
      return buffer_reset if quiet
      if msg.respond_to? :each
        msg.each do |msg_line|
          @line_buffer += msg_line
        end
      else
        @line_buffer += msg
      end
      return unless flush && @to_console && @msg_queue.nil?
      STDOUT.print @line_buffer
      STDOUT.flush
      buffer_reset
    end
    alias :buf :buffer

    def buffer_reset
      @buffer = ''
    end

    def join( sep = nil )
      return '' if @msg_queue.blank?
      return @msg_queue.join if sep.nil?
      return @msg_queue.join sep
    end

    def line( msg, log: LOG_NONE )
      case log
      when LOG_NONE
        # do nothing
      when LOG_DEBUG
        logger.debug msg
      when LOG_ERROR
        logger.error msg
      when LOG_INFO
        logger.info msg
      when LOG_WARN
        logger.warn msg
      else
        # do nothing
      end
      @msg_queue << msg unless @msg_queue.nil?
      puts msg if @to_console
    end

    def logger
      @logger ||= Rails.logger
    end

    def msg( msg = nil, log: LOG_NONE, prefix: PREFIX_NONE )
      return buffer_reset if quiet
      msg_raw( msg, log: log, prefix: prefix )
    end

    def msg_debug( msg, log: false, &block )
      return buffer_reset if quiet
      return buffer_reset unless debug_verbose
      msg_raw( msg, log: (log ? LOG_DEBUG : LOG_NONE), prefix: PREFIX_DEBUG, &block )
    end

    def msg_error( msg, log: false, &block )
      msg_raw( msg, log: (log ? LOG_ERROR : LOG_NONE), prefix: PREFIX_ERROR, &block )
    end

    def msg_info( msg, log: false, &block )
      return buffer_reset if quiet
      msg_raw( msg, log: (log ? LOG_INFO : LOG_NONE), prefix: PREFIX_INFO, &block )
    end

    def msg_verbose( msg, log: false, prefix: PREFIX_NONE, &block )
      return buffer_reset if quiet
      return buffer_reset unless verbose || debug_verbose
      msg_raw( msg, log: (log ? LOG_INFO : LOG_NONE), prefix: prefix, &block )
    end

    def msg_warn( msg, log: false, &block )
      msg_raw( msg, log: (log ? LOG_WARN : LOG_NONE), prefix: PREFIX_WARN, &block )
    end

    private

    def msg_raw( msg = nil, log: LOG_NONE, prefix: PREFIX_NONE )
      msg_no_block( msg, log: log, prefix: prefix ) unless msg.nil?
      return unless block_given?
      msg = yield
      msg_no_block( msg, log: log, prefix: prefix ) unless msg.nil?
    end

    def msg_no_block( msg, log: LOG_NONE, prefix: PREFIX_NONE )
      if msg.respond_to? :each
        msg.each do |msg_line|
          if @buffer.present?
            line("#{@msg_prefix}#{prefix}#{@buffer}#{msg}", log: log )
            buffer_reset
          else
            line( "#{@msg_prefix}#{prefix}#{msg_line}", log: log )
          end
        end
      elsif @buffer.present?
        line("#{@msg_prefix}#{prefix}#{@buffer}#{msg}", log: log )
        buffer_reset
      else
        line("#{@msg_prefix}#{prefix}#{msg}", log: log )
      end
    end

  end

end
