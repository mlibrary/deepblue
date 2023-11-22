# frozen_string_literal: true

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_task'

  class ExportLogFilesTask < AbstractTask

    def initialize( options: {} )
      super( options: options )
    end

    def run
      ExportFilesHelper.export_log_files( msg_handler: msg_handler, debug_verbose: false )
    end

  end

end
