# frozen_string_literal: true

require_relative './cleanup_all_task'

module Aptrust

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

aptrust_weekly_cleanup:
  # Run Wednesday and Friday at 6 or 7 PM (depending on DST)
  # Note: all parameters are set in the rake task job
  #      M H  D Mo WDay
  cron: '0 23 * *  3,5'
  class: RakeTaskJob
  queue: scheduler
  description: Run rake task aptrust:all_uploads_report
  args:
    by_request_only: false
    hostnames:
       - 'deepblue.lib.umich.edu'
    job_delay: 0
    subscription_service_id: aptrust_upload_report
    rake_task: "aptrust:cleanup_weekly"

END_OF_SCHEDULER_ENTRY

  class CleanupWeeklyTask < ::Aptrust::CleanupAllTask

    mattr_accessor :cleanup_weekly_task_debug_verbose, default: false

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # bundle exec rake aptrust:cleanup_all['{"verbose":false\,"test_mode":false\,"date_end":"now - 1 week"\,"email_targets":"fritx@umich.edu"\,"email_subject":"Aptrust weekly cleanup on %hostname% finished %now%"}']
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @test_mode = false
      @date_end = DateTime.now - 1.week
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "Aptrust week-old cleanup on %hostname% finished at %now%"
      @msg_handler.msg_debug "date_end: #{@date_end}"
      @msg_handler.msg_debug "export_all_files: #{@export_all_files}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
    end

  end

end
