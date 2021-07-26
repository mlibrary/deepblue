
Hyrax::AnonymousLinkService.setup do |config|

  config.enable_anonymous_links = true

  config.anonymous_link_controller_behavior_debug_verbose = false
  config.anonymous_link_service_debug_verbose = false
  config.anonymous_links_controller_debug_verbose = false
  config.anonymous_links_viewer_controller_debug_verbose = false

  config.anonymous_link_show_delete_button = false
  config.anonymous_link_destroy_if_published = true
  config.anonymous_link_destroy_if_tombstoned = true

end
