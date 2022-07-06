# frozen_string_literal: true

module Deepblue

  class MessageHandlerDebugOnly < MessageHandlerNull

    @debug_verbose = nil

    def initialize( debug_verbose: ->() { false },
                    logger: Rails.logger,
                    msg_prefix: false,
                    msg_queue: nil,
                    to_console: false,
                    verbose: false  )

      @debug_verbose = debug_verbose
      @debug_verbose ||= ->() { false }
      @logger = logger
    end

    def bold_debug( msg = nil,
                    bold_puts: false,
                    label: nil,
                    key_value_lines: true,
                    add_stack_trace: false,
                    add_stack_trace_depth: 3,
                    lines: 1,
                    logger: nil,
                    &block )

      return unless debug_verbose
      logger ||= self.logger
      LoggingHelper.bold_debug( msg,
                                bold_puts: false,
                                label: label,
                                key_value_lines: key_value_lines,
                                add_stack_trace: add_stack_trace,
                                add_stack_trace_depth: add_stack_trace_depth,
                                lines: lines,
                                logger: logger,
                                &block )
    end

    def debug_verbose
      @debug_verbose.call
    end

    def logger
      @logger ||= Rails.logger
    end

  end

end
