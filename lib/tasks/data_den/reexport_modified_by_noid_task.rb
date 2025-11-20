# frozen_string_literal: true

require_relative './abstract_reexport_task'

module DataDen

  class ReexportModifiedByNoidTask < ::DataDen::AbstractReexportTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      msg_handler.msg_verbose
      noids_sort
      if noid_pairs.present?
        run_pair_exports
      else
        run_noids_reexport
      end
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'DataDen::ExportByNoid', event: 'ExportByNoid' )
    end

  end

end
