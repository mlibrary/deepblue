# frozen_string_literal: true

require_relative './abstract_upload_task'

module Aptrust

  class ReuploadModifiedTask < ::Aptrust::AbstractUploadTask

    attr_accessor :export_all_files

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @sort = true
      @export_all_files = option_value( key: 'export_all_files', default_value: false )
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
      w = ::Aptrust::WorkCache.new( msg_handler: msg_handler )
      ::Aptrust::Status.all.each do |status|
        # msg_handler.msg_verbose "status=#{status.pretty_inspect}" if debug_verbose
        # puts "status=#{status.pretty_inspect}"
        next if status.event == ::Aptrust::EVENT_DELETED
        w.reset.noid = status.noid
        if !w.work_present?
          msg_handler.msg_warn "Failed to load work with noid: #{status.noid}"
          next
        end
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

    def uploader_for( noid: )
      if export_all_files
        export_files_sets_filter_date = nil
      else
        export_files_sets_filter_date = status_created_at( noid: noid )
      end
      uploader = ::Aptrust::AptrustUploadWork.new( msg_handler: msg_handler, debug_verbose: debug_verbose,
                                                   bag_max_total_file_size: bag_max_total_file_size,
                                                   cleanup_after_deposit: cleanup_after_deposit,
                                                   cleanup_bag: cleanup_bag,
                                                   cleanup_bag_data: cleanup_bag_data,
                                                   debug_assume_upload_succeeds: debug_assume_upload_succeeds,
                                                   event_start: event_start,
                                                   event_stop: event_stop,
                                                   export_file_sets_filter_date: export_files_sets_filter_date,
                                                   noid: noid,
                                                   track_status: track_status,
                                                   zip_data_dir: zip_data_dir )
      return uploader
    end

  end

end
