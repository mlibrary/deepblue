# frozen_string_literal: true

require_relative './abstract_file_sys_export_service'

class DataDenExportService < AbstractFileSysExportService

  mattr_accessor :data_den_export_debug_verbose, default: false

  def self.test_it( debug_verbose: false )
    msg_handler = ::Deepblue::MessageHandler.msg_handler_for( task: true, verbose: true, debug_verbose: debug_verbose )
    service = DataDenExportService.new( msg_handler: msg_handler,
                                        options: { force_export: true,
                                                   skip_export: false,
                                                   test_mode: false } )
    w = DataSet.all.first
    # w = DataSet.all.last
    w.file_set_ids.size
    service.export_data_set( work: w )
  end

  def initialize( msg_handler: nil, options: nil )
    super( base_path_published:   FileSysExportIntegrationService.data_den_base_path_published,
           base_path_unpublished: FileSysExportIntegrationService.data_den_base_path_unpublished,
           export_type:           FileSysExportIntegrationService.data_den_export_type,
           link_path_to_globus:   FileSysExportIntegrationService.data_den_link_path_to_globus,
           msg_handler:           msg_handler,
           options:               options )
  end

end
