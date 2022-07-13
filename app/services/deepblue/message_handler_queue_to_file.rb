# frozen_string_literal: true

module Deepblue

  class MessageHandlerQueueToFile < MessageHandler

    def self.msg_handler_for( task: true,
                              task_id: nil,
                              msg_queue_file: nil,
                              append: false,
                              debug_verbose: DEFAULT_DEBUG_VERBOSE,
                              msg_prefix: MessageHandler::DEFAULT_MSG_PREFIX,
                              to_console: MessageHandler::DEFAULT_TO_CONSOLE,
                              verbose: MessageHandler::DEFAULT_VERBOSE )

      if msg_queue_file.blank?
        if task_id.blank?
          msg_queue_file ||= "./log/%timestamp%.log"
        else
          msg_queue_file ||= "./log/%timestamp%.#{task_id}.log"
        end
      end
      if task
        MessageHandlerQueueToFile.new( msg_queue_file: msg_queue_file,
                                       append: append,
                                       debug_verbose: debug_verbose,
                                       msg_prefix: msg_prefix,
                                       to_console: true,
                                       verbose: verbose )
      else
        MessageHandlerQueueToFile.new( msg_queue_file: msg_queue_file,
                                       append: append,
                                       debug_verbose: debug_verbose,
                                       msg_prefix: msg_prefix,
                                       to_console: to_console,
                                       verbose: verbose )
      end
    end

    attr_accessor :append
    attr_writer :msg_queue_file

    def initialize( msg_queue_file:,
                    append: false,
                    debug_verbose: DEFAULT_DEBUG_VERBOSE,
                    msg_prefix: DEFAULT_MSG_PREFIX,
                    to_console: DEFAULT_TO_CONSOLE,
                    verbose: DEFAULT_VERBOSE  )

      super( debug_verbose: debug_verbose,
             msg_prefix: msg_prefix,
             msg_queue: nil,
             to_console: to_console,
             verbose: verbose )
      @append = append
      @msg_queue_file_parm = msg_queue_file
    end

    def msg_queue_file
      @msg_queue_file ||= msg_queue_file_init
    end

    def msg_queue_file_truncate
      File.open( msg_queue_file, 'w' ) { |out| out << ''; out.flush }
    end

    protected

    def msg_no_block( msg, log: LOG_NONE, prefix: PREFIX_NONE )
      # This is not thread safe
      begin
        @out = nil
        @out = File.open( msg_queue_file, 'a' )
        super( msg, log: log, prefix: prefix )
      ensure
        unless @out.nil?
          @out.flush
          @out.close
        end
      end
    end

    def msg_queue_file_init
      file_path = @msg_queue_file_parm
      file_path = ReportHelper.expand_path_partials file_path
      file_path = File.absolute_path file_path
      File.open( file_path, 'w' ) { |out| out << ''; out.flush } unless append
      return file_path
    end

    def queue_msg( msg )
      @out.puts msg
    end

  end


end
