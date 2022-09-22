
Deepblue::TeamdynamixIntegrationService.setup do |config|

  puts "Deepblue::TeamdynamixIntegrationService.setup"

  begin
  ## configure teamdynamix integration

  verbose_init = true

  puts "Deepblue::TeamdynamixIntegrationService.setup starting..." if verbose_init

  config.teamdynamix_integration_service_debug_verbose = false
  config.teamdynamix_service_debug_verbose = false

  # config.teamdynamix_service_active = true

  config.tdx_rest_url = 'https://apigw-tst.it.umich.edu'

  puts "config.tdx_rest_url=#{config.tdx_rest_url}" if verbose_init

  if config.tdx_rest_url == 'https://apigw-tst.it.umich.edu'
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
  else

  end

  puts "Deepblue::TeamdynamixIntegrationService.setup finished" if verbose_init

  rescue Exception => e
    puts "Exception: #{e.to_s}"
  end

end
