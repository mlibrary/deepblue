# frozen_string_literal: true

require_relative './export_task'

module DataDen

  class ExportReportTask < ::DataDen::ExportTask

    mattr_accessor :export_report_task_debug_verbose, default: true

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # bundle exec rake1 data_den:export['{"verbose":true\,"test_mode":true\,"email_targets":"fritx@umich.edu"\,"email_subject":"DataDen exports on %hostname% remaining as of %now%"}']
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @test_mode = true
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "DataDen exports on %hostname% remaining as of %now%"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
    end

  end

end
