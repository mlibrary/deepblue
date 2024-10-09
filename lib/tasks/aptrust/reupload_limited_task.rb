# frozen_string_literal: true

require_relative './reupload_modified_task'

module Aptrust

  class ReuploadLimitedTask < ::Aptrust::ReuploadModifiedTask

    mattr_accessor :reupload_limited_task_debug_verbose, default: true

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # nohup bundle exec rake aptrust:reupload_modified['{"verbose":true\,"test_mode":false\,"export_all_files":false\,"cleanup_after_deposit":false\,"email_targets":"fritx@umich.edu"\,"email_subject":"Aptrust re-uploads on %hostname% as of %now%"}'] > /deepbluedata-prep/aptrust_work/logs/20240927_reupload_1.out 2>&1 &
      @verbose = true
      @msg_handler.verbose = @verbose
      @msg_handler.msg_queue = []
      # @msg_handler.debug_verbose = reupload_limited_task_debug_verbose
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
      #                                       "@msg_handler=#{@msg_handler.pretty_inspect}" ] if reupload_limited_task_debug_verbose
      @test_mode = false
      @cleanup_after_deposit = false
      @export_all_files = true
      @max_size = 1.terabyte
      @email_targets = ["fritx@umich.edu"]
      @email_subject = "Aptrust re-uploads on %hostname% finished at %now% max size 1tb"
      @msg_handler.msg_verbose "cleanup_after_deposit: #{@cleanup_after_deposit}"
      @msg_handler.msg_verbose "export_all_files: #{@export_all_files}"
      @msg_handler.msg_verbose "max_size: #{human_readable_size( @max_size )}"
      @msg_handler.msg_verbose "email_targets: #{@email_targets}"
      @msg_handler.msg_verbose "email_subject: #{@email_subject}"
      @msg_handler.msg_verbose "test_mode: #{@test_mode}"
    end

  end

end