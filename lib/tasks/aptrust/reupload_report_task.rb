# frozen_string_literal: true

require_relative './reupload_task'
require_relative './reupload_modified_task'

module Aptrust

  class ReuploadReportTask < ::Aptrust::ReuploadModifiedTask

    mattr_accessor :reupload_report_task_debug_verbose, default: false

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # bundle exec rake aptrust:reupload_modified['{"verbose":true\,"test_mode":true\,"email_targets":"fritx@umich.edu"\,"email_subject":"Aptrust re-uploads on %hostname% as of %now%"}']
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @test_mode = true
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "Aptrust re-uploads on %hostname% as of %now%"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
    end

  end

end
