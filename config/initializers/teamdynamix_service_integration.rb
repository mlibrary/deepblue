
Deepblue::TeamdynamixIntegrationService.setup do |config|

  verbose_init = true

  begin
    puts "Deepblue::TeamdynamixIntegrationService.setup starting..." if verbose_init

    config.teamdynamix_integration_service_debug_verbose = false
    config.teamdynamix_service_debug_verbose = false
    # config.teamdynamix_service_active = true # override value in local settings
    config.enforce_dbd_account_id = false

    puts "config.tdx_server=#{config.tdx_server}" if verbose_init
    if 'test' == config.tdx_server
      puts "congigure test teamdynamix" if verbose_init
      config.its_app_id            = 31
      config.tdx_url               = 'https://teamdynamix.umich.edu/SBTDNext/Apps/'
      config.ulib_app_id           = 87
      config.account_id            = 3111 # verify for sandbox
      config.form_id               = 2220
      config.service_id            = 2643 # ULIB-DBRRDS
      config.type_id               = 773 # is this correct (was 769)
      config.responsible_group_id  = 1240
      # custom attributes
      config.attr_depositor_status = 10215 # db-DepositorStatus, id: 10215
      config.attr_discipline       = 10218 # db-Discipline, id: 10218
      config.attr_related_pub      = 10216 # db-relatedpub, id: 10216
      config.attr_req_participants = 10220 # db-ReqParticipants, id: 10220
      config.attr_summary          = 10228 # db-Summary, id: 10228
      config.attr_uid              = 10219 # db-UID, id: 10219
      config.attr_url_in_dbd       = 10217 # db-URLinDBdata, id: 10217
    elsif 'prod' == config.tdx_server
      puts "congigure production teamdynamix" if verbose_init
      config.its_app_id            = 31
      config.tdx_url               = 'https://teamdynamix.umich.edu/TDNext/Apps/'
      config.ulib_app_id           = 87
      config.account_id            = 3111 # MI Publishing-DBlue&RData
      config.form_id               = 2277
      config.service_id            = 2667 # ULIB-Deep Blue - Data Deposit
      config.type_id               = 780
      config.responsible_group_id  = 1233
      # TODO: custom attributes
      config.attr_depositor_status = 10413 # db-DepositorStatus, id: 10413
      config.attr_discipline       = 10422 # db-Discipline, id: 10422
      config.attr_related_pub      = 10411 # db-relatedpub, id: 10411
      config.attr_req_participants = 10423 # db-ReqParticipant, id: 10423
      config.attr_summary          = 10425 # db-Summary, id: 10425
      config.attr_uid              = 10424 # db-UID, id: 10424
      config.attr_url_in_dbd       = 10409 # db-URLinDBdata, id: 10409
    else
      puts "skip congigure teamdynamix" if verbose_init
      # ignore
    end
    puts "Deepblue::TeamdynamixIntegrationService.setup finished" if verbose_init
  rescue Exception => e
    puts "Deepblue::TeamdynamixIntegrationService.setup caught an exception"
    puts "Exception: #{e.to_s}"
  end

end
