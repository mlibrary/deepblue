
Deepblue::AnalyticsIntegrationService.setup do |config|

  config.event_tracking_debug_verbose = true
  config.event_tracking_include_request_uri = false
  config.event_tracking_excluded_parameters = [ :authenticity_token ].freeze

end
