# frozen_string_literal: true

module Deepblue

  # NULL_MESSAGE_HANDLER = MessageHandlerNull.new unless const_defined? :NULL_MESSAGE_HANDLER

  class MessageHandlerNull

    def initialize( debug_verbose: false,
                    msg_prefix: false,
                    msg_queue: nil,
                    to_console: false,
                    verbose: false  )

      # ignore inputs
    end

    def debug_verbose
      false
    end
    def debug_verbose=(_x); end

    def msg_prefix
      ''
    end
    def msg_prefix=(_x); end

    def msg_queue
      nil
    end
    def msg_queue=(_x); end

    def to_console
      false
    end
    def to_console=(_x); end

    def verbose
      false
    end
    def verbose=(_x); end

    def block_called_from(offset=2, prefix: 'block called from: ')
      return ''
    end

    def self.block_called_from(offset=2, prefix: 'block called from: ')
      return ''
    end

    def bold_debug( _msg = nil,
                    bold_puts: false,
                    label: nil,
                    key_value_lines: true,
                    add_stack_trace: false,
                    add_stack_trace_depth: 3,
                    lines: 1,
                    logger: nil,
                    &block )

      # ignore
    end

    def buffer( _msg, flush: true )
      # ignore
    end
    alias :buf :buffer

    def buffer_reset
      # ignore
    end

    def called_from(offset=1, prefix: 'called from: ')
      return ''
    end

    def self.called_from(offset=1, prefix: 'called from: ')
      return ''
    end

    def here(offset=0, prefix: '')
      return ''
    end

    def self.here(offset=0, prefix: '')
      return ''
    end

    def join( _sep = nil )
      return ''
    end

    def line( _msg, log: nil )
      # ignore
    end

    def line_buffer
      return nil
    end

    def line_buffer=
      # ignore
    end

    def logger
      nil
    end

    def msg( _msg = nil, log: nil, prefix: nil, &block )
      # ignore
    end

    def msg_debug( msg = nil, log: false, &block )
      # ignore
    end

    def msg_debug_bold( msg = nil, log: false, &block )
      # ignore
    end

    def msg_error( _msg = nil, log: false, &block )
      # ignore
    end

    def msg_info( _msg = nil, log: false, &block )
      # ignore
    end

    def msg_verbose( _msg = nil, log: false, prefix: nil, &block )
      # ignore
    end

    def msg_warn( _msg = nil, log: false, &block )
      # ignore
    end

    def msg_exception( exception, include_backtrace: true, log: false, backtrace: 20, force_to_console: false )
      # ignore
    end

    def msg_with_rv( rv, msg:, log: nil, prefix: nil )
      return rv
    end

    def msg_if?( rv, msg:, log: nil, prefix: nil )
      return rv
    end

    def msg_unless?( rv, msg:, log: nil, prefix: nil )
      return rv
    end

    def msg_error_with_rv( rv, msg:, log: nil )
      return rv
    end

    def msg_error_if?( rv, msg:, log: nil )
      return rv
    end

    def msg_error_unless?( rv, msg:, log: nil )
      return rv
    end

    def null_msg_handler?
      true
    end

    def reset
      # ignore
      re
    end
    alias :clear :reset

    def user_pacifier( x = nil )
      # ignore
    end
    alias :pacify :user_pacifier

  end

end
