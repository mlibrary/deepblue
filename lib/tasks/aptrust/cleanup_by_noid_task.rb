# frozen_string_literal: true

require_relative './abstract_cleanup_task'

module Aptrust

  class CleanupByNoidTask < ::Aptrust::AbstractCleanupTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Starting..."
      noids.each { |noid| cleanup_by_noid( noid: noid ) }
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'Aptrust::CleanupByNoidTask', event: 'CleanupByNoidTask' )
    end

  end

end
