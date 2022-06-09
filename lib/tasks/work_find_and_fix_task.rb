# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../app/services/deepblue/find_and_fix_service'
require_relative '../../app/services/deepblue/message_handler'

module Deepblue

  class WorkFindAndFixTask < AbstractTask

    def initialize( id:, options: {} )
      @id = id
      super( options: options )
    end

    def run
      msg_handler = MessageHandler.new( msg_queue: nil, task: true )
      FindAndFixService.work_find_and_fix( id: @id,
                                           msg_handler: msg_handler,
                                           task: true,
                                           debug_verbose: false )
    end

  end

end
