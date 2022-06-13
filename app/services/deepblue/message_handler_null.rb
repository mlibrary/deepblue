# frozen_string_literal: true

module Deepblue

  # NULL_MESSAGE_HANDLER = MessageHandlerNull.new unless const_defined? :NULL_MESSAGE_HANDLER

  class MessageHandlerNull

    def initialize( debug_verbose: false,
                    msg_prefix: '',
                    msg_queue: [],
                    # task: false,
                    to_console: false,
                    verbose: false )

      # ignore inputs
    end

    def debug_verbose
      false
    end
    def debug_verbose(_x); end

    def msg_prefix
      ''
    end
    def msg_prefix(_x); end

    def msg_queue
      nil
    end
    def msg_queue=(_x); end

    # def task
    #   false
    # end
    # def task=(_x); end

    def to_console
      false
    end
    def to_console=(_x); end

    def verbose
      false
    end
    def verbose=(_x); end


    def join( _sep = '' )
      return ''
    end

    def line( _msg )
      # ignore
    end

    def msg( _msg, prefix: '' )
      # ignore
    end

    def msg_debug( _msg )
      # ignore
    end

    def msg_error( _msg )
      # ignore
    end

    def msg_verbose( _msg, prefix: '' )
      # ignore
    end

    def msg_warn( _msg )
      # ignore
    end

  end

end
