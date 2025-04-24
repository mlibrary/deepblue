# frozen_string_literal: true

require_relative './abstract_export_task'

module DataDen

  class ExportTask < ::DataDen::AbstractExportTask

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
      run_pair_exports
      run_email_targets( subject: 'DataDen::ExportTask', event: 'ExportTask' )
      msg_handler.msg_verbose "Finished."
    end

    def run_find
      @noids = []
      test_dates_init
      dsc = ::DataSetCache.new
      msg_handler.msg_verbose "ExportTask.run_find"
      all_solr.each do |doc|
        # msg_handler.msg_verbose "ExportTask.run_find all_solr doc.id= #{doc.id}"
        dsc.reset_with doc
        # if !dsc.data_set_present?
        #   msg_handler.msg_warn "Failed to load data_set with noid #{dsc.noid}"
        #   next
        # end
        # next unless dsc&.file_set_ids.present?
        # next unless dsc.file_set_ids.size > 0
        # next unless dsc.published?
        # msg_handler.msg_verbose "Filter dsc.date_modified=#{dsc.date_modified}"
        # msg_handler.msg_verbose "Filter #{test_date_begin} < #{dsc.date_modified} < #{test_date_end} ?"
        # msg_handler.msg_verbose "next unless #{test_date_begin} <= #{dsc.date_modified} = #{test_date_begin <= dsc.date_modified}"
        # msg_handler.msg_verbose "next unless #{dsc.date_modified} <= #{test_date_end} = #{dsc.date_modified <= test_date_end}"
        next unless @test_date_begin <= dsc.date_modified
        next unless dsc.date_modified <= @test_date_end
        next if FileSysExport.has_status?( noid: dsc.id )
        @noids << dsc.id
      end
    end

  end

end
