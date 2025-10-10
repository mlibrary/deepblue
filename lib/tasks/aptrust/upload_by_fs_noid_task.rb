# frozen_string_literal: true

require_relative './abstract_upload_task'

module Aptrust

  class UploadByFsNoidTask < ::Aptrust::AbstractUploadTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      # assumes noid is a file set
      msg_handler.msg_verbose
      run_fs_noids_upload
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'Aptrust::UploadByNoid', event: 'UploadByNoid' )
    end

  end

end
