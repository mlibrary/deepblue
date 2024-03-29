# frozen_string_literal: true

require_relative '../../app/services/deepblue/find_and_fix_service'

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_task'

  class WorkFindAndFixTask < AbstractTask

    def initialize( id:, options: {} )
      @id = id
      super( options: options )
    end

    def run
      FindAndFixService.work_find_and_fix( id: @id, msg_handler: msg_handler )
    end

  end

end
