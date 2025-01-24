
FileSysExportIntegrationService.setup do |config|

  begin

    config.file_sys_export_integration_debug_verbose = false

    case Rails.configuration.hostname
    when ::Deepblue::InitializationConstants::HOSTNAME_PROD
      config.data_den_base_path             = '/deepbluedata-prep-new/DataDen/prod/'
      config.data_den_base_path_published   = '/deepbluedata-prep-new/DataDen/prod/published/'
      config.data_den_base_path_unpublished = '/deepbluedata-prep-new/DataDen/prod/unpublished/'
    when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
      config.data_den_base_path             = '/deepbluedata-prep/DataDen/test/'
      config.data_den_base_path_published   = '/deepbluedata-prep/DataDen/test/published/'
      config.data_den_base_path_unpublished = '/deepbluedata-prep/DataDen/test/unpublished/'
    when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
      #
    when ::Deepblue::InitializationConstants::HOSTNAME_TEST
        config.data_den_base_path             = './data/DataDen/'
        config.data_den_base_path_published   = './data/DataDen/published/'
        config.data_den_base_path_unpublished = './data/DataDen/unpublished/'
    when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
      config.data_den_base_path             = '/Users/fritx/DataDen/'
      config.data_den_base_path_published   = '/Users/fritx/DataDen/published/'
      config.data_den_base_path_unpublished = '/Users/fritx/DataDen/unpublished/'
    else

    end

  rescue Exception => e
    puts e
    raise
  end

end