# frozen_string_literal: true

module Deepblue

  class MessageHandler

    attr_accessor :debug_verbose, :msg_prefix, :msg_queue, :to_console, :verbose

    def initialize( debug_verbose: false,
                    msg_prefix: '',
                    msg_queue: [],
                    # task: false,
                    to_console: false,
                    verbose: false )

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

    def msg( msg, prefix: '' )
      if msg.is_a? Array
        msg.each do |msg_line|
          line "#{@msg_prefix}#{prefix}#{msg_line}"
        end
      else
        line "#{@msg_prefix}#{prefix}#{msg}"
      end
    end

    def msg_error( msg )
      msg msg, prefix: 'ERROR: '
    end

    def msg_verbose( msg, prefix: '' )
      msg( msg, prefix: prefix ) if @verbose
    end

    def msg_warn( msg )
      msg msg, prefix: 'WARNING: '
    end

  end

end
