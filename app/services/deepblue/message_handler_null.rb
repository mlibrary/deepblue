# frozen_string_literal: true

module Deepblue

  # NULL_MESSAGE_HANDLER = MessageHandlerNull.new unless const_defined? :NULL_MESSAGE_HANDLER

  class MessageHandlerNull

    def initialize( msg_prefix: '', msg_queue: nil, task: false, verbose: false )
      # ignore inputs
    end

    def msg_prefix
      ''
    end
    def msg_prefix(x); end

    def msg_queue
      nil
    end
    def msg_queue=(x); end

    def task
      false
    end
    def task=(x); end

    def verbose
      false
    end
    def verbose=(x); end

    def join( sep = nil )
      return ''
    end

    def msg( msg )
      # ignore
    end

    def msg_verbose( msg )
      # ignore
    end

  end

end
