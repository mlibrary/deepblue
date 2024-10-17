# frozen_string_literal: true

require_relative './abstract_upload_task'
require_relative './reupload_report_task'
require_relative './upload_report_task'

module Aptrust

  class AllUploadsReportTask < ::Aptrust::AbstractUploadTask

    mattr_accessor :reupload_report_task_debug_verbose, default: true

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @test_mode = true
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "All aptrust uploads on %hostname% as of %now%"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
    end

    def run
      debug_verbose
      msg_handler.msg_verbose
      msg_handler.msg_verbose "New Uploads:"
      task = UploadReportTask.new( msg_handler: msg_handler, options: { 'email_results' => false } )
      task.run
      msg_handler.msg_verbose "Reuploads (modified since previous upload):"
      task = ReuploadReportTask.new( msg_handler: msg_handler, options: { 'email_results' => false } )
      task.run
      run_email_targets( subject: @email_subject, event: 'AllUploadsReport' )
      msg_handler.msg_verbose "Finished report."
    end

  end

end
