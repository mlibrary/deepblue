
BrowseEverythingIntegrationService.setup do |config|

  begin
    config.browse_everything_browser_debug_verbose = false
    config.browse_everything_controller_debug_verbose = true
    config.browse_everything_controller2_debug_verbose = false
    config.browse_everything_driver_authentication_factory_debug_verbose = true
    config.browse_everything_driver_base_debug_verbose = true
    config.browse_everything_driver_base2_debug_verbose = false
    config.browse_everything_driver_dropbox_debug_verbose = true
    config.browse_everything_driver_dropbox2_debug_verbose = false
    config.browse_everything_views_debug_verbose = true
  rescue Exception => e
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace[0..20].join("\n")
  end

  # puts ">>>>>>>>>BrowseEverythingIntegrationService.setup finished<<<<<<<<<"

end
