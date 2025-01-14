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
      @report_file = '%date%.data_den_all_work_statuses.csv'
      @report_file = File.join report_dir, @report_file
      @report_file = ::Deepblue::ReportHelper.expand_path_partials @report_file
      @report_file = File.absolute_path @report_file
    end

    def run_report
      run_report_file_init
      msg_handler.msg_verbose "report_file=#{report_file}"
      begin
        header = %w[noid work_modified work_size work_size_hr export_status status_created_at status_updated_at]
        csv_out << header
        # writer header
        test_dates_init
        w = ::DataSetCache.new
        w_all.each do |work|
          w.reset.work = work
          if !w.work_present?
            msg_handler.msg_warn "Failed to load work" #" with noid #{status.noid}"
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
          report_line( work: w )
        end
      ensure
        if @csv_out.present?
          @csv_out.flush
          @csv_out.close
        end
      end
    end

    def report_line( work: )
      noid = work.id
      work_modified = datetime_local_time( work.date_modified, format: "%Y/%m/%d %H:%M:%S" )
      work_size = work.total_file_size
      work_size_hr = readable_sz( work_size )
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
      row = [ noid, work_modified, work_size, work_size_hr, export_status, status_created_at, status_updated_at ]
      csv_out << row
    end

  end

end
