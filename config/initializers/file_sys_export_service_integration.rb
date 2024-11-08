
FileSysExportIntegrationService.setup do |config|

  begin

    config.file_sys_export_integration_debug_verbose = false

    case Rails.configuration.hostname
    when ::Deepblue::InitializationConstants::HOSTNAME_PROD

    when ::Deepblue::InitializationConstants::HOSTNAME_TESTING

    when ::Deepblue::InitializationConstants::HOSTNAME_STAGING

    when ::Deepblue::InitializationConstants::HOSTNAME_TEST

    when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL

    else

    end

  rescue Exception => e
    puts e
    raise
  end

end
