# frozen_string_literal: true

require_relative './reupload_task'

module Aptrust

  class ReuploadReportTask < ::Aptrust::ReuploadModifiedTask

    mattr_accessor :reupload_report_task_debug_verbose, default: true

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # bundle exec rake aptrust:reupload_modified['{"verbose":true\,"test_mode":true\,"email_targets":"fritx@umich.edu"\,"email_subject":"Aptrust re-uploads on %hostname% as of %now%"}']
      @verbose = true
      @msg_handler.verbose = @verbose
      @msg_handler.msg_queue = []
      # @msg_handler.debug_verbose = reupload_report_task_debug_verbose
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
      #                                       "@msg_handler=#{@msg_handler.pretty_inspect}" ] if reupload_report_task_debug_verbose
      @test_mode = true
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "Aptrust re-uploads on %hostname% as of %now%"
      @msg_handler.msg_verbose "test_mode: #{@test_mode}"
      @msg_handler.msg_verbose "email_targets: #{@email_targets}"
      @msg_handler.msg_verbose "email_subject: #{@email_subject}"
    end

  end

end
