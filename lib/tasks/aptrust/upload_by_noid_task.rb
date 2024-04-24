# frozen_string_literal: true

require_relative './abstract_upload_task'

module Aptrust

  class UploadByNoidTask < ::Aptrust::AbstractUploadTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      msg_handler.msg_verbose
      noids_sort
      if noid_pairs.present?
        run_pair_uploads
      else
        run_noids_upload
      end
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'Aptrust::UploadByNoid', event: 'UploadByNoid' )
    end

  end

end
