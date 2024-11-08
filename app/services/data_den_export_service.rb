# frozen_string_literal: true

class DataDenExportService < AbstractFileSysExportService

  mattr_accessor :data_den_export_debug_verbose, default: false

  def self.test_it( debug_verbose: false )
    msg_handler = ::Deepblue::MessageHandler.msg_handler_for( task: true, verbose: true, debug_verbose: debug_verbose )
    service = DataDenExportService.new( msg_handler: msg_handler, options: { skip_export: true, test_mode: true } )
    w = DataSet.all.first
    w.file_set_ids.size
    service.export_data_set( work: w )
  end

  def initialize( msg_handler: nil, options: nil )
    super( base_path_published:   FileSysExportIntegrationService.data_den_base_path_published,
           base_path_unpublished: FileSysExportIntegrationService.data_den_base_path_unpublished,
           export_type:           FileSysExportIntegrationService.data_den_export_type,
           msg_handler:           msg_handler,
           options:               options )
  end

end
