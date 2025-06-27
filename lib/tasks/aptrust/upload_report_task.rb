# frozen_string_literal: true

require_relative './upload_task'

module Aptrust

  class UploadReportTask < ::Aptrust::UploadTask

    mattr_accessor :upload_report_task_debug_verbose, default: false

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # bundle exec rake1 aptrust:upload['{"verbose":true\,"test_mode":true\,"email_targets":"fritx@umich.edu"\,"email_subject":"Aptrust uploads on %hostname% remaining as of %now%"}']
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @test_mode = true
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "Aptrust uploads on %hostname% remaining as of %now%"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
    end

  end

end
