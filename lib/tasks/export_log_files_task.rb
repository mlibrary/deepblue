# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../app/helpers/deepblue/export_files_helper'

module Deepblue

  class ExportLogFilesTask < AbstractTask

    def initialize( options: {} )
      super( options: options )
    end

    def run
      ExportFilesHelper.export_log_files( msg_handler: msg_handler,
                                          task: true,
                                          verbose: verbose,
                                          debug_verbose: false )
    end

  end

end
