# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../app/helpers/deepblue/export_files_helper'
require_relative '../../app/services/deepblue/message_handler'

module Deepblue

  class ExportLogFilesTask < AbstractTask

    def initialize( options: {} )
      super( options: options )
    end

    def run
      msg_handler = MessageHandler.new( msg_queue: nil, task: true )
      ExportFilesHelper.export_log_files( msg_handler: msg_handler,
                                          task: true,
                                          verbose: verbose,
                                          debug_verbose: false )
    end

  end

end
