# frozen_string_literal: true

require_relative './upload_task'

module Aptrust

  class UploadLimitedTask < ::Aptrust::UploadTask

    mattr_accessor :upload_limited_task_debug_verbose, default: true

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # nohup bundle exec rake aptrust:upload['{"verbose":true\,"email_targets":"fritx@umich.edu"\,"email_subject":"Aptrust upload on %hostname% finished at %now% max size 250gb"\,"max_size":"250gb"\,"cleanup_after_deposit":false}'] > /deepbluedata-prep/aptrust_work/logs/20241030_upload_1.out 2>&1 &
      @verbose = true
      @msg_handler.verbose = @verbose
      @msg_handler.msg_queue = []
      # @msg_handler.debug_verbose = upload_limited_task_debug_verbose
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
      #                                       "@msg_handler=#{@msg_handler.pretty_inspect}" ] if upload_limited_task_debug_verbose
      @test_mode = false
      @cleanup_after_deposit = false
      @max_size = 1.terabyte
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "Aptrust upload on %hostname% finished at %now% max size 1tb"
      @msg_handler.msg_debug "cleanup_after_deposit: #{@cleanup_after_deposit}"
      @msg_handler.msg_debug "max_size: #{human_readable_size( @max_size )}"
      @msg_handler.msg_debug "email_targets: #{@email_targets}"
      @msg_handler.msg_debug "email_subject: #{@email_subject}"
      @msg_handler.msg_debug "test_mode: #{@test_mode}"
    end

  end

end
