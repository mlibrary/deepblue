
Deepblue::TeamdynamixIntegrationService.setup do |config|
  ## configure teamdynamix integration
  verbose_init = true

  TDX_REST_URL_TEST = 'https://apigw-tst.it.umich.edu'
  TDX_REST_URL_PROD = 'https://apigw.it.umich.edu' # TODO: verifty

  begin
    puts "Deepblue::TeamdynamixIntegrationService.setup starting..." if verbose_init

    config.teamdynamix_integration_service_debug_verbose = false
    config.teamdynamix_service_debug_verbose = false
    # config.teamdynamix_service_active = true

    program_name = Rails.configuration.program_name
    puts "program_name=#{program_name}" if verbose_init
    puts "Rails.configuration.hostname=#{Rails.configuration.hostname}" if verbose_init
    case Rails.configuration.hostname
    when ::Deepblue::InitializationConstants::HOSTNAME_PROD
      config.tdx_rest_url = TDX_REST_URL_TEST
    when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
      config.tdx_rest_url = TDX_REST_URL_TEST
    when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
      config.tdx_rest_url = TDX_REST_URL_TEST
    when ::Deepblue::InitializationConstants::HOSTNAME_TEST
      config.tdx_rest_url = nil
    when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
      config.tdx_rest_url = TDX_REST_URL_TEST
    else
      config.tdx_rest_url = nil
    end
    puts "config.tdx_rest_url=#{config.tdx_rest_url}" if verbose_init

    if config.tdx_rest_url == TDX_REST_URL_TEST
      config.its_app_id            = 31
      config.tdx_url               = 'https://teamdynamix.umich.edu/SBTDNext/Apps/'
      config.ulib_app_id           = 87
      # custom attributes
      config.attr_depositor_status = 10215 # db-DepositorStatus, id: 10215
      config.attr_discipline       = 10218 # db-Discipline, id: 10218
      config.attr_related_pub      = 10216 # db-relatedpub, id: 10216
      config.attr_req_participants = 10220 # db-ReqParticipants, id: 10220
      config.attr_summary          = 10228 # db-Summary, id: 10228
      config.attr_uid              = 10219 # db-UID, id: 10219
      config.attr_url_in_dbd       = 10217 # db-URLinDBdata, id: 10217
    elsif config.tdx_rest_url == TDX_REST_URL_PROD
      config.its_app_id            = 31
      config.tdx_url               = 'https://teamdynamix.umich.edu/TDNext/Apps/'
      config.ulib_app_id           = 87 # verify for prod
      # TODO: custom attributes
      # config.attr_depositor_status = 10215 # db-DepositorStatus, id: 10215
      # config.attr_discipline       = 10218 # db-Discipline, id: 10218
      # config.attr_related_pub      = 10216 # db-relatedpub, id: 10216
      # config.attr_req_participants = 10220 # db-ReqParticipants, id: 10220
      # config.attr_summary          = 10228 # db-Summary, id: 10228
      # config.attr_uid              = 10219 # db-UID, id: 10219
      # config.attr_url_in_dbd       = 10217 # db-URLinDBdata, id: 10217
    end
    puts "Deepblue::TeamdynamixIntegrationService.setup finished" if verbose_init
  rescue Exception => e
    puts "Deepblue::TeamdynamixIntegrationService.setup caught an exception"
    puts "Exception: #{e.to_s}"
  end

end
