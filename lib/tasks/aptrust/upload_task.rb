# frozen_string_literal: true

require_relative './abstract_upload_task'

module Aptrust

  class UploadTask < ::Aptrust::AbstractUploadTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @sort = true
    end

    def run
      debug_verbose
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Started..."
      run_find
      noids_sort
      run_pair_uploads
      run_email_targets( subject: 'Aptrust::UploadTask', event: 'UploadTask' )
      msg_handler.msg_verbose "Finished."
    end

    def run_find
      @noids = []
      test_dates_init
      w = ::Aptrust::WorkCache.new
      w_all.each do |work|
        w.reset.work = work
        if !w.work_present?
          msg_handler.msg_warn "Failed to load work with noid #{status.noid}"
          next
        end
        next unless w&.file_set_ids.present?
        next unless w.file_set_ids.size > 0
        next unless w.published?
        # msg_handler.msg_verbose "Filter w.date_modified=#{w.date_modified}"
        # msg_handler.msg_verbose "Filter #{test_date_begin} < #{w.date_modified} < #{test_date_end} ?"
        # msg_handler.msg_verbose "next unless #{test_date_begin} <= #{w.date_modified} = #{test_date_begin <= w.date_modified}"
        # msg_handler.msg_verbose "next unless #{w.date_modified} <= #{test_date_end} = #{w.date_modified <= test_date_end}"
        next unless @test_date_begin <= w.date_modified
        next unless w.date_modified <= @test_date_end
        next if ::Aptrust::Status.has_status?( cc: w )
        @noids << w.id
      end
    end

  end

end
