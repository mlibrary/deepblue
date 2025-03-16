# frozen_string_literal: true

require_relative './abstract_export_task'

module DataDen

  class AbstractReexportTask < ::DataDen::AbstractExportTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    #def run_export( noid:, size: nil )
    #  run_reexport( noid: noid, size: size )
    #end

  end

end
