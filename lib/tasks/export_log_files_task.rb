# frozen_string_literal: true

require_relative '../../app/helpers/deepblue/export_files_helper'

module Deepblue

  class ExportLogFilesTask < AbstractTask

    def initialize( options: {} )
      super( options: options )
    end

    def run
      ::Deepblue::ExportFilesHelper.export_log_files( task: true, verbose: verbose )
    end

  end

end
