# frozen_string_literal: true

require_relative './cleanup_all_task'

module Aptrust

  class CleanupReportTask < ::Aptrust::CleanupAllTask

    mattr_accessor :cleanup_report_task_debug_verbose, default: true

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @verbose = true
      @msg_handler.verbose = @verbose
      @msg_handler.msg_queue = []
      # @msg_handler.debug_verbose = cleanup_report_task_debug_verbose
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
      #                                       "@msg_handler=#{@msg_handler.pretty_inspect}" ] if cleanup_report_task_debug_verbose
      # bundle exec rake aptrust:cleanup_all['{"verbose":true\,"test_mode":true\,"email_targets":"fritx@umich.edu"\,"email_subject":"Aptrust report cleanup on %hostname% finished %now%"}']
      @test_mode = true
      # @date_end = DateTime.now - 1.week
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "Aptrust report cleanup on %hostname% finished at %now%"
      @msg_handler.msg_debug "date_end: #{@date_end}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
    end

  end

end
