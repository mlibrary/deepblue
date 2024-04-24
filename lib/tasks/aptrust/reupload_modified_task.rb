# frozen_string_literal: true

require_relative './abstract_upload_task'

module Aptrust

  class ReuploadModifiedTask < ::Aptrust::AbstractUploadTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      msg_handler.msg_verbose "@options=#{@options.pretty_inspect}"
      @sort = true
    end

    def run
      debug_verbose
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Started..."
      run_find
      noids_sort
      run_pair_uploads
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'Aptrust::ReuploadModifiedTask', event: 'ReuploadModifiedTask' )
    end

    def run_find
      @noids = []
      test_dates_init
      w = WorkCache.new
      ::Aptrust::Status.all.each do |status|
        # msg_handler.msg_verbose "status=#{status.pretty_inspect}" if debug_verbose
        w.reset.noid = status.noid
        status_create_date = status.created_at
        work_modified_date = w.date_modified
        next if work_modified_date < status_create_date

        # msg_handler.msg_verbose "Filter status.timestamp=#{status.timestamp}"
        # msg_handler.msg_verbose "Filter #{test_date_begin} < #{status.timestamp} < #{test_date_end} ?"
        # msg_handler.msg_verbose "next unless #{test_date_begin} <= #{status.timestamp} = #{test_date_begin <= status.timestamp}"
        # msg_handler.msg_verbose "next unless #{status.timestamp} <= #{test_date_end} = #{status.timestamp <= test_date_end}"
        next unless @test_date_begin <= status.timestamp
        next unless status.timestamp <= @test_date_end

        @noids << w.id
      end
    end

  end

end
