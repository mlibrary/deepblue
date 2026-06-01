# frozen_string_literal: true

require_relative './upload_task'

module Aptrust

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

aptrust_upload_one_unlimited:
  # Run Monday and Wednesday starting at 10 AM (which is offset by 4 or [5 during daylight savings time], due to GMT)
  # Note: all parameters are set in the rake task job
  #      M H  D Mo WDay
  cron: '0 15 * *  1'
  class: RakeTaskJob
  queue: scheduler
  description: Run rake task aptrust:upload_one_unlimited
  args:
    by_request_only: true
    hostnames:
       - 'deepblue.lib.umich.edu'
    job_delay: 0
    subscription_service_id: aptrust_upload_one_unlimited
    rake_task: "aptrust:upload_one_unlimited"

  END_OF_SCHEDULER_ENTRY

  class UploadOneUnlimitedTask < ::Aptrust::UploadTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @test_mode = false
      @cleanup_after_deposit = false
      #@max_size = 1.terabyte
      @min_size = 1.terabyte - 1
      @max_uploads = 1
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "Aptrust upload one unlimited on %hostname% finished at %now%"
      @msg_handler.msg_debug "cleanup_after_deposit: #{@cleanup_after_deposit}"
      #@msg_handler.msg_debug "max_size: #{human_readable_size( @max_size )}"
      @msg_handler.msg_debug "min_size: #{human_readable_size( @min_size )}"
      @msg_handler.msg_debug "max_uploads: #{human_readable_size( @max_uploads )}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
    end

  end

end
