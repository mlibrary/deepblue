
Deepblue::AnalyticsIntegrationService.setup do |config|

  # see: config/features.rb for Flipflop.enable_local_analytics_ui

  config.ahoy_tracker_debug_verbose = false
  config.analytics_helper_debug_verbose = false

  config.event_tracking_debug_verbose = false
  config.event_tracking_include_request_uri = false
  config.event_tracking_excluded_parameters = [ :authenticity_token ].freeze

  config.enable_chartkick = true
  config.enable_collections_hit_graph = false
  config.enable_file_sets_hit_graph = true
  config.enable_works_hit_graph = true
  if config.enable_chartkick
    config.hit_graph_view_level = 2 # 0 = none, 1 = admin, 2 = editor, 3 = everyone
  else
    config.hit_graph_view_level = 0 # 0 = none, 1 = admin, 2 = editor, 3 = everyone
  end
  config.hit_graph_day_window = 30 # set to < 1 for no limit

  config.monthly_events_report_subscription_id = 'MonthlyEventsReport'

  config.analytics_reports_admins_can_subscribe = true

end
