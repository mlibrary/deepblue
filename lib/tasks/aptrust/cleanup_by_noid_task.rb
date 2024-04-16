# frozen_string_literal: true

require_relative './abstract_cleanup_task'

module Aptrust

  class CleanupByNoidTask < ::Aptrust::AbstractCleanupTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      puts
      puts "debug_verbose=#{debug_verbose}"
      noids.each { |noid| cleanup_by_noid( noid: noid ) }
      puts "Finished."
    end

  end

end
