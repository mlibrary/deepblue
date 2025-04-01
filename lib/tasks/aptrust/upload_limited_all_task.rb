# frozen_string_literal: true

require_relative './abstract_upload_task'
require_relative './reupload_limited_task'
require_relative './upload_limited_task'

module Aptrust

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

aptrust_upload:
  # Run Monday and Wednesday starting at 9 AM (which is offset by 4 or [5 during daylight savings time], due to GMT)
  # Note: all parameters are set in the rake task job
  #      M H  D Mo WDay
  cron: '0 14 * *  1,3'
  class: RakeTaskJob
  queue: scheduler
  description: Run rake task aptrust:upload_limited_all
  args:
    by_request_only: false
    hostnames:
       - 'deepblue.lib.umich.edu'
    job_delay: 0
    subscription_service_id: aptrust_upload
    rake_task: "aptrust:upload_limited_all"

END_OF_SCHEDULER_ENTRY

  class UploadLimitedAllTask < ::Aptrust::AbstractUploadTask

    mattr_accessor :upload_limited_all_task_debug_verbose, default: true

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
      @email_subject = "APTrust upload limited all on %hostname% as of %now%"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
    end

    def run
      debug_verbose
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Upload New:"
      task = UploadLimitedTask.new( msg_handler: msg_handler, options: { 'email_results' => false } )
      task.run
      msg_handler.msg_verbose "Reupload Modified:"
      task = ReuploadLimitedTask.new( msg_handler: msg_handler, options: { 'email_results' => false } )
      task.run
      run_email_targets( subject: @email_subject, event: 'UploadLimitedAllTask' )
      msg_handler.msg_verbose "Finished upload all."
    end

  end

end
