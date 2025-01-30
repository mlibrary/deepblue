# frozen_string_literal: true

require_relative './abstract_reexport_task'

module DataDen

  class ReexportModifiedTask < ::DataDen::AbstractReexportTask

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
      run_pair_exports
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'DataDen::ReexportModifiedTask', event: 'ReexportModifiedTask' )
    end

    def run_find
      @noids = []
      test_dates_init
      dsc = DataSetCache.new( msg_handler: msg_handler )
      export_service.file_sys_exports.each do |fs_rec|
        # msg_handler.msg_verbose "fs_rec=#{fs_rec.pretty_inspect}" if debug_verbose
        # puts "fs_rec=#{fs_rec.pretty_inspect}"
        next if fs_rec.export_status == ::FileSysExportC::STATUS_DELETED
        dsc.reset_with fs_rec.noid
        if !dsc.data_set_present?
          msg_handler.msg_warn "Failed to load work with noid #{fs_rec.noid}"
          next
        end
        rec_create_date = fs_rec.created_at
        ds_modified_date = dsc.date_modified
        next if ds_modified_date < rec_create_date

        # msg_handler.msg_verbose "Filter fs_rec.export_status_timestamp=#{fs_rec.export_status_timestamp}"
        # msg_handler.msg_verbose "Filter #{test_date_begin} < #{fs_rec.export_status_timestamp} < #{test_date_end} ?"
        # msg_handler.msg_verbose "next unless #{test_date_begin} <= #{fs_rec.export_status_timestamp} = #{test_date_begin <= fs_rec.export_status_timestamp}"
        # msg_handler.msg_verbose "next unless #{fs_rec.export_status_timestamp} <= #{test_date_end} = #{fs_rec.export_status_timestamp <= test_date_end}"
        next unless @test_date_begin <= fs_rec.export_status_timestamp
        next unless fs_rec.export_status_timestamp <= @test_date_end

        @noids << dsc.id
      end
    end

  end

end
