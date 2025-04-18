# frozen_string_literal: true

require_relative '../../app/helpers/deepblue/ticket_helper'

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_task'

  class WorkTicketAddCommentTask < AbstractTask

    def initialize( id:, comment:, options: {} )
      @id = id
      @comment = comment
      super( options: options )
      @new_status_id = task_options_value( key: 'new_status_id', default_value: 0 )
      @notify = task_options_value( key: 'notify', default_value: '' )
    end

    def run
      notify = []
      notify = [@notify] unless @notify.blank?
      TicketHelper.ticket_add_comment( cc_id: @id,
                                       comment: @comment,
                                       notify: notify,
                                       new_status_id: @new_status_id,
                                       msg_handler: msg_handler,
                                       debug_verbose: debug_verbose )
    end

  end

end
