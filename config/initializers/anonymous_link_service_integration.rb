
Hyrax::AnonymousLinkService.setup do |config|

  config.enable_anonymous_links = true

  config.anonymous_link_service_debug_verbose = false

  config.anonymous_link_but_not_really = false
  config.anonymous_link_default_expiration_duration = 365.days
  config.anonymous_link_use_detailed_human_readable_time = true

end
