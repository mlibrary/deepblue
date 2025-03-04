# frozen_string_literal: true

require_relative './abstract_export_task'

module DataDen

  class CleanByNoidTask < ::DataDen::AbstractExportTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      msg_handler.msg_verbose
      run_noids_clean
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'DataDen::CleanByNoid', event: 'ExportByNoid' )
    end

    def run_clean( noid:, size: nil )
      msg_handler.msg_verbose "sleeping for #{sleep_secs}" if 0 < sleep_secs
      sleep( sleep_secs ) if 0 < sleep_secs
      msg = "Cleaning: #{noid}"
      msg += " - #{readable_sz(size)}" if size.present?
      msg_handler.msg_verbose msg
      msg_handler.msg_verbose "Test mode: #{test_mode?}"
      return if test_mode?
      export_service.date_set_clean( noid: noid )
    end

    def run_noids_clean
      total_size = 0
      dsc = DataSetCache.new
      noids.each do |noid|
        dsc.reset_with noid
        if !dsc.data_set_present?
          msg_handler.msg_warn "Failed to load data set with noid #{noid}"
          next
        end
        run_clean( noid: noid )
      end
    end

  end

end
