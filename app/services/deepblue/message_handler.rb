# frozen_string_literal: true

module Deepblue

  class MessageHandler

    DEFAULT_DEBUG_VERBOSE = false
    DEFAULT_MSG_PREFIX = ''.freeze
    DEFAULT_TO_CONSOLE = false
    DEFAULT_VERBOSE = false

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

    attr_accessor :debug_verbose, :msg_prefix, :msg_queue, :to_console, :verbose

    def initialize( debug_verbose: DEFAULT_DEBUG_VERBOSE,
                    msg_prefix: DEFAULT_MSG_PREFIX,
                    msg_queue: [],
                    to_console: DEFAULT_TO_CONSOLE,
                    verbose: DEFAULT_VERBOSE )

      @debug_verbose = debug_verbose
      @msg_prefix = msg_prefix
      @msg_prefix ||= ''
      @msg_queue = msg_queue
      @to_console = to_console
      @verbose = verbose
    end

    def join( sep = nil )
      return '' if @msg_queue.blank?
      return @msg_queue.join if sep.nil?
      return @msg_queue.join sep
    end

    def line( msg )
      Rails.logger.debug if debug_verbose
      @msg_queue << msg unless @msg_queue.nil?
      puts msg if @to_console
    end

    def msg( msg = nil, prefix: '' )
      msg_no_block( msg, prefix: prefix ) unless msg.nil?
      return unless block_given?
      msg = yield
      msg_no_block( msg, prefix: prefix ) unless msg.nil?
    end

    def msg_debug( msg, &block )
      msg( msg, prefix: 'DEBUG: ', &block ) if @debug_verbose
    end

    def msg_error( msg, &block )
      msg( msg, prefix: 'ERROR: ', &block )
    end

    def msg_verbose( msg, prefix: '', &block )
      msg( msg, prefix: prefix, &block ) if @verbose || @debug_verbose
    end

    def msg_warn( msg, &block )
      msg( msg, prefix: 'WARNING: ', &block )
    end

    private

    def msg_no_block( msg, prefix: '' )
      if msg.respond_to? :each
        msg.each do |msg_line|
          line "#{@msg_prefix}#{prefix}#{msg_line}"
        end
      else
        line "#{@msg_prefix}#{prefix}#{msg}"
      end
    end

  end

end
