# frozen_string_literal: true

require_relative './abstract_report_task'

module DataDen

  class ReportAllTask < ::DataDen::AbstractReportTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Starting..."
      run_report
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'DataDen::ReportAllTask', event: 'ReportAllTask' )
    end

    def run_report_file_init
      return if @report_file.present?
      @report_file = '%date%.data_den_all_data_set_statuses.csv'
      @report_file = File.join report_dir, @report_file
      @report_file = ::Deepblue::ReportHelper.expand_path_partials @report_file
      @report_file = File.absolute_path @report_file
    end

    def run_report
      run_report_file_init
      msg_handler.msg_verbose "report_file=#{report_file}"
      begin
        header = %w[noid data_set_modified data_set_size data_set_size_hr export_status status_created_at status_updated_at]
        csv_out << header
        # writer header
        test_dates_init
        dsc = ::DataSetCache.new
        dsc_all.each do |data_set|
          dsc.reset.data_set = data_set
          if !dsc.data_set_present?
            msg_handler.msg_warn "Failed to load data_set" #" with noid #{status.noid}"
            next
          end
          # next unless dsc&.file_set_ids.present?
          # next unless dsc.file_set_ids.size > 0
          # next unless dsc.published?
          # msg_handler.msg_verbose "Filter dsc.date_modified=#{dsc.date_modified}"
          # msg_handler.msg_verbose "Filter #{test_date_begin} < #{dsc.date_modified} < #{test_date_end} ?"
          # msg_handler.msg_verbose "next unless #{test_date_begin} <= #{dsc.date_modified} = #{test_date_begin <= dsc.date_modified}"
          # msg_handler.msg_verbose "next unless #{dsc.date_modified} <= #{test_date_end} = #{dsc.date_modified <= test_date_end}"
          next unless @test_date_begin <= dsc.date_modified
          next unless dsc.date_modified <= @test_date_end
          report_line( data_set: dsc )
        end
      ensure
        if @csv_out.present?
          @csv_out.flush
          @csv_out.close
        end
      end
    end

    def report_line( data_set: )
      noid = data_set.id
      data_set_modified = datetime_local_time( data_set.date_modified, format: "%Y/%m/%d %H:%M:%S" )
      data_set_size = data_set.total_file_size
      data_set_size_hr = readable_sz( data_set_size )
      file_sys_export_rec = file_sys_export( noid: noid )
      if file_sys_export_rec.present?
        export_status = file_sys_export_rec.export_status
        status_created_at = file_sys_export_rec.created_at
        status_updated_at = file_sys_export_rec.created_at
      else
        export_status = ""
        status_created_at = ""
        status_updated_at = ""
      end
      row = [ noid, data_set_modified, data_set_size, data_set_size_hr, export_status, status_created_at, status_updated_at ]
      csv_out << row
    end

  end

end
