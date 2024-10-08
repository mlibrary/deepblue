# frozen_string_literal: true

require_relative './cleanup_all_task'

module Aptrust

  class CleanupWeeklyTask < ::Aptrust::CleanupAllTask

    mattr_accessor :cleanup_weekly_task_debug_verbose, default: true

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # bundle exec rake aptrust:cleanup_all['{"verbose":false\,"test_mode":false\,"date_end":"now - 1 week"\,"email_targets":"fritx@umich.edu"\,"email_subject":"Aptrust weekly cleanup on %hostname% finished %now%"}']
      @verbose = true
      @msg_handler.verbose = @verbose
      @msg_handler.msg_queue = []
      # @msg_handler.debug_verbose = cleanup_weekly_task_debug_verbose
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
      #                                       "@msg_handler=#{@msg_handler.pretty_inspect}" ] if cleanup_weekly_task_debug_verbose
      @test_mode = false
      @date_end = DateTime.now - 1.week
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "Aptrust week-old cleanup on %hostname% finished at %now%"
      @msg_handler.msg_verbose "date_end: #{@date_end}"
      @msg_handler.msg_verbose "export_all_files: #{@export_all_files}"
      @msg_handler.msg_verbose "email_targets: #{@email_targets}"
      @msg_handler.msg_verbose "email_subject: #{@email_subject}"
      @msg_handler.msg_verbose "test_mode: #{@test_mode}"
    end

  end

end
