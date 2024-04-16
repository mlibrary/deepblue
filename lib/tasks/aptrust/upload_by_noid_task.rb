# frozen_string_literal: true

require_relative './abstract_upload_task'

module Aptrust

  class UploadByNoidTask < ::Aptrust::AbstractUploadTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      puts
      puts "debug_verbose=#{debug_verbose}"
      noids_sort
      if noid_pairs.present?
        noid_pairs.each { |pair| run_upload( noid: pair[:noid], size: pair[:size] ) }
      else
        noids.each { |noid| run_upload( noid: noid ) }
      end
      puts "Finished."
    end

  end

end
