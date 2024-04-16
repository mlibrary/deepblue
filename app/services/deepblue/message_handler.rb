# frozen_string_literal: true

module Deepblue

  class MessageHandler

    DEFAULT_DEBUG_VERBOSE = false
    DEFAULT_MSG_PREFIX = ''.freeze
    DEFAULT_QUIET = false
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

    def self.msg_handler_for_job( msg_queue: [], options: {} )
      options = OptionsHelper.parse options
      debug_verbose = OptionsHelper.value( options, key: 'debug_verbose', default_value: DEFAULT_DEBUG_VERBOSE )
      verbose       = OptionsHelper.value( options, key: 'verbose',       default_value: DEFAULT_VERBOSE )
      msg_prefix    = OptionsHelper.value( options, key: 'msg_prefix',    default_value: DEFAULT_MSG_PREFIX )
      msg_queue     = OptionsHelper.value( options, key: 'msg_queue',     default_value: msg_queue )
      to_console    = OptionsHelper.value( options, key: 'to_console',    default_value: false )
      rv = MessageHandler.new( debug_verbose: debug_verbose,
                               msg_prefix: msg_prefix,
                               msg_queue: msg_queue,
                               to_console: to_console,
                               verbose: verbose )
      if OptionsHelper.error? options
        rv.msg_warn "options error #{options[:error]}"
      end
      rv.quiet = OptionsHelper.value( options, key: 'quiet', default_value: DEFAULT_QUIET )
      return rv
    end

    def self.msg_handler_for_task( msg_queue: nil, options: {} )
      options = OptionsHelper.parse options
      debug_verbose = OptionsHelper.value( options, key: 'debug_verbose', default_value: DEFAULT_DEBUG_VERBOSE )
      verbose       = OptionsHelper.value( options, key: 'verbose',       default_value: DEFAULT_VERBOSE )
      msg_prefix    = OptionsHelper.value( options, key: 'msg_prefix',    default_value: DEFAULT_MSG_PREFIX )
      msg_queue     = OptionsHelper.value( options, key: 'msg_queue',     default_value: msg_queue )
      to_console    = OptionsHelper.value( options, key: 'to_console',    default_value: true )
      rv = MessageHandler.new( debug_verbose: debug_verbose,
                               msg_prefix: msg_prefix,
                               msg_queue: msg_queue,
                               to_console: to_console,
                               verbose: verbose )
      if OptionsHelper.error? options
        rv.msg_warn "options error #{options[:error]}"
      end
      rv.quiet = OptionsHelper.value( options, key: 'quiet', default_value: DEFAULT_QUIET )
      return rv
    end

    def self.msg_handler_null( debug_verbose: false,
                               msg_prefix: false,
                               msg_queue: nil,
                               to_console: false,
                               verbose: false  )

      @@message_handler_null ||= MessageHandlerNull.new.freeze
    end

    def self.option_value( options, key:, default_value: nil, verbose: false )
      # options = @options
      return default_value if options.blank?
      return default_value unless options.key? key
      return options[key]
    end

    # if set to quiet, then all messages except warnings and errors will be ignored
    attr_reader :quiet
    alias :quiet? :quiet

    attr_accessor :debug_verbose, :msg_prefix, :msg_queue, :to_console
    attr_reader :verbose
    attr_writer :logger
    attr_accessor :line_buffer

    def initialize( debug_verbose: DEFAULT_DEBUG_VERBOSE,
                    msg_prefix: DEFAULT_MSG_PREFIX,
                    msg_queue: [],
                    to_console: DEFAULT_TO_CONSOLE,
                    verbose: DEFAULT_VERBOSE ) # TODO: add logger as parameter

      @debug_verbose = debug_verbose
      @msg_prefix = msg_prefix
      @msg_prefix ||= PREFIX_NONE
      @msg_queue = msg_queue
      @quiet = DEFAULT_QUIET
      @to_console = to_console
      @verbose = verbose
      @line_buffer = ''
    end

    def block_called_from(offset=2, prefix: 'block called from: ')
      "#{prefix}#{caller_locations(1, offset+1)[offset]}"
    end

    def self.block_called_from(offset=2, prefix: 'block called from: ')
      "#{prefix}#{caller_locations(1, offset+1)[offset]}"
    end

    # Provide the same functionality as the LoggingHelper.bold_debug, but override bold_puts parameter
    # with the MessageHandler's to_console flag, and use the MessageHandler's logger, which defaults
    # to Rails.logger
    def bold_error( msg = nil,
                    bold_puts: @to_console,
                    label: nil,
                    key_value_lines: true,
                    add_stack_trace: false,
                    add_stack_trace_depth: 3,
                    lines: 1,
                    logger: nil, # defaults to the MessageHandler's logger
                    &block )

      if to_console
        LoggingHelper.bold_puts( msg,
                                 label: label,
                                 key_value_lines: key_value_lines,
                                 add_stack_trace: add_stack_trace,
                                 add_stack_trace_depth: add_stack_trace_depth,
                                 lines: lines,
                                 &block )
      else
        logger ||= self.logger
        LoggingHelper.bold_error( msg,
                                  bold_puts: bold_puts,
                                  label: label,
                                  key_value_lines: key_value_lines,
                                  add_stack_trace: add_stack_trace,
                                  add_stack_trace_depth: add_stack_trace_depth,
                                  lines: lines,
                                  logger: logger,
                                  &block )
      end
    end

    # Provide the same functionality as the LoggingHelper.bold_debug, but override bold_puts parameter
    # with the MessageHandler's to_console flag, and use the MessageHandler's logger, which defaults
    # to Rails.logger
    def bold_debug( msg = nil,
                    bold_puts: @to_console,
                    label: nil,
                    key_value_lines: true,
                    add_stack_trace: false,
                    add_stack_trace_depth: 3,
                    lines: 1,
                    logger: nil, # defaults to the MessageHandler's logger
                    &block )

      return unless debug_verbose
      if to_console
        LoggingHelper.bold_puts( msg,
                                 label: label,
                                 key_value_lines: key_value_lines,
                                 add_stack_trace: add_stack_trace,
                                 add_stack_trace_depth: add_stack_trace_depth,
                                 lines: lines,
                                 &block )
      else
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
      @line_buffer = ''
    end

    def called_from(offset=1, prefix: 'called from: ')
      "#{prefix}#{caller_locations(1, offset+1)[offset]}"
    end

    def self.called_from(offset=1, prefix: 'called from: ')
      "#{prefix}#{caller_locations(1, offset+1)[offset]}"
    end

    def here(offset=0, prefix: '')
      "#{prefix}#{caller_locations(1, offset+1)[offset]}"
    end

    def self.here(offset=0, prefix: '')
      "#{prefix}#{caller_locations(1, offset+1)[offset]}"
    end

    def join( sep = "\n" )
      return '' if @msg_queue.blank?
      return @msg_queue.join if sep.nil?
      return @msg_queue.join sep
    end

    def line( msg, log: LOG_NONE )
      log_line( msg, log: log )
      queue_msg msg
      puts_to_console msg
    end

    def logger
      @logger ||= Rails.logger
    end

    def mask( arg, always: false, keys: [], dupe: true )
      return arg if !always && Rails.env.development?
      return 'x' * arg.to_s.size unless keys.present? && arg.respond_to?(:keys)
      arg = arg.dup if dupe
      arg.stringify_keys!
      keys.each do |key|
        arg[key] = mask( arg[key], always: always, keys: keys, dupe: false ) if arg.has_key? key.to_s
      end
      return arg
    end

    def msg( msg = nil, log: LOG_NONE, prefix: PREFIX_NONE, &block )
      return buffer_reset if quiet
      msg_raw( msg, log: (log ? LOG_INFO : LOG_NONE), prefix: prefix, &block )
    end

    def msg_debug( msg = nil, log: false, &block )
      return buffer_reset if quiet
      return buffer_reset unless debug_verbose
      msg_raw( msg, log: (log ? LOG_DEBUG : LOG_NONE), prefix: PREFIX_DEBUG, &block )
    end

    def msg_debug_bold( msg = nil, log: false, &block )
      return buffer_reset if quiet
      return buffer_reset unless debug_verbose
      bold_debug( msg, logger: (log ? LOG_DEBUG : LOG_NONE), &block )
    end

    def msg_error( msg = nil, log: false, &block )
      msg_raw( msg, log: (log ? LOG_ERROR : LOG_NONE), prefix: PREFIX_ERROR, &block )
    end

    def msg_info( msg = nil, log: false, &block )
      return buffer_reset if quiet
      msg_raw( msg, log: (log ? LOG_INFO : LOG_NONE), prefix: PREFIX_INFO, &block )
    end

    def msg_verbose( msg = nil, log: false, prefix: PREFIX_NONE, &block )
      return buffer_reset if quiet
      return buffer_reset unless verbose || debug_verbose
      msg_raw( msg, log: (log ? LOG_INFO : LOG_NONE), prefix: prefix, &block )
    end

    def msg_warn( msg = nil, log: false, &block )
      msg_raw( msg, log: (log ? LOG_WARN : LOG_NONE), prefix: PREFIX_WARN, &block )
    end

    def msg_exception( exception, include_backtrace: true, log: false, backtrace: 20, force_to_console: false )
      save_to_console = to_console if force_to_console
      @to_console = true if force_to_console
      msg_error("#{exception.class} #{exception.message} at #{exception.backtrace[0]}", log: log )
      if include_backtrace
        backtrace ||= 20
        unless backtrace.is_a? Integer
          backtrace = backtrace.to_s.to_i
        end
        if backtrace > 1
          msg_error( exception.backtrace[0..backtrace], log: log )
        else
          msg_error( exception.backtrace, log: log )
        end
      end
      @to_console = save_to_console if force_to_console
    end

    def msg_with_rv( rv, msg:, log: LOG_NONE, prefix: PREFIX_NONE )
      msg( msg, log: log, prefix: prefix )
      return rv
    end

    def msg_if?( rv, msg:, log: LOG_NONE, prefix: PREFIX_NONE )
      msg( msg, log: log, prefix: prefix ) if rv
      return rv
    end

    def msg_unless?( rv, msg:, log: LOG_NONE, prefix: PREFIX_NONE )
      msg( msg, log: log, prefix: prefix ) unless rv
      return rv
    end

    def msg_error_with_rv( rv, msg:, log: LOG_NONE )
      msg_error( msg, log: log )
      return rv
    end

    def msg_error_if?( rv, msg:, log: LOG_NONE )
      msg_error( msg, log: log ) if rv
      return rv
    end

    def msg_error_unless?( rv, msg:, log: LOG_NONE )
      msg_error( msg, log: log ) unless rv
      return rv
    end

    def null_msg_handler?
      false
    end

    def obj_class( label, obj )
      "#{label}.class=#{obj.class.name}"
    end

    def quiet=(is_quiet)
      @quiet = is_quiet
      @verbose = false if @quiet
    end

    def reset
      @user_pacifier_chars = 0
      @msg_queue.clear unless @msg_queue.blank?
      @line_buffer = ''
    end
    alias :clear :reset

    def user_pacifier( x = '.' )
      return unless to_console
      return if x.blank?
      x = x.to_s.split
      @user_pacifier_chars ||= 0
      @user_pacifier_chars += x.size
      x.each { |c| STDOUT.putc c };STDOUT.flush
      return if @user_pacifier_chars < 80
      STDOUT.puts '';STDOUT.flush
      @user_pacifier_chars = 0
    end
    alias :pacify :user_pacifier

    def verbose=(is_verbose)
      @verbose = is_verbose
      @quiet = false if @verbose
    end

    protected

    def log_line( msg, log: )
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
    end

    def msg_no_block( msg, log: LOG_NONE, prefix: PREFIX_NONE )
      if msg.respond_to? :each
        msg.each do |msg_line|
          if @line_buffer.present?
            line("#{@msg_prefix}#{prefix}#{@line_buffer}#{msg}", log: log )
            buffer_reset
          else
            line( "#{@msg_prefix}#{prefix}#{msg_line}", log: log )
          end
        end
      elsif @line_buffer.present?
        line("#{@msg_prefix}#{prefix}#{@line_buffer}#{msg}", log: log )
        buffer_reset
      else
        line("#{@msg_prefix}#{prefix}#{msg}", log: log )
      end
    end

    def puts_to_console( msg )
      return unless @to_console
      puts msg
      STDOUT.flush
    end

    def queue_msg( msg )
      return if @msg_queue.nil?
      @msg_queue << msg
    end

    def msg_raw( msg = nil, log: LOG_NONE, prefix: PREFIX_NONE )
      msg_no_block( msg, log: log, prefix: prefix ) unless msg.nil?
      return unless block_given?
      msg = yield
      return if msg.nil?
      msg_no_block( msg, log: log, prefix: prefix )
    end

  end

end
