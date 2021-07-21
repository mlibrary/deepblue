
Hyrax::SingleUseLinkService.setup do |config|

  config.enable_single_use_links = false

  config.single_use_link_controller_behavior_debug_verbose = false
  config.single_use_link_service_debug_verbose = false
  config.single_use_links_controller_debug_verbose = false
  config.single_use_links_viewer_controller_debug_verbose = false

  config.single_use_link_but_not_really = false
  config.single_use_link_default_expiration_duration = 365.days
  config.single_use_link_use_detailed_human_readable_time = true

end
