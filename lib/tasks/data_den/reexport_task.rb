# frozen_string_literal: true

require_relative './abstract_export_task'

module DataDen

  class ReexportTask < ::DataDen::AbstractExportTask

    attr_accessor :export_status

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @sort = true
      @event = option_export_status
    end

    def option_export_status
      opt = task_options_value( key: 'export_status', default_value: nil )
      opt = opt.strip if opt.is_a? String
      msg_handler.msg_verbose "export_status='#{opt}'"
      return opt
    end

    def run
      debug_verbose
      msg_handler.msg_verbose "msg_handler=#{msg_handler.pretty_inspect}"
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Started..."
      run_find
      noids_sort
      run_pair_exports
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'DataDen::ReexportTask', event: 'ReexportTask' )
    end

    def run_find
      @noids = []
      test_dates_init
      export_service.file_sys_exports.each do |fs_rec|
        # msg_handler.msg_verbose "fs_rec=#{fs_rec.pretty_inspect}" if debug_verbose
        next if fs_rec.export_status == FileSysExportC::STATUS_DELETED
        next if export_status.present? && fs_rec.export_status != export_status
        # msg_handler.msg_verbose "Filter fs_rec.export_status_timestamp=#{fs_rec.export_status_timestamp}"
        # msg_handler.msg_verbose "Filter #{test_date_begin} < #{fs_rec.export_status_timestamp} < #{test_date_end} ?"
        # msg_handler.msg_verbose "next unless #{test_date_begin} <= #{fs_rec.export_status_timestamp} = #{test_date_begin <= fs_rec.export_status_timestamp}"
        # msg_handler.msg_verbose "next unless #{fs_rec.export_status_timestamp} <= #{test_date_end} = #{fs_rec.export_status_timestamp <= test_date_end}"
        next unless @test_date_begin <= fs_rec.export_status_timestamp
        next unless fs_rec.export_status_timestamp <= @test_date_end

        @noids << fs_rec.noid
      end
    end

  end

end
