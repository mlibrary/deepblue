
Deepblue::AnalyticsIntegrationService.setup do |config|

  config.event_tracking_debug_verbose = true
  config.event_tracking_include_request_uri = false
  config.event_tracking_excluded_parameters = [ :authenticity_token ].freeze

  config.enable_chartkick = false
  config.enable_collections_hit_graph = false
  config.enable_file_sets_hit_graph = true
  config.enable_works_hit_graph = true
  if config.enable_chartkick
    config.hit_graph_view_level = 1 # 0 = none, 1 = admin, 2 = editor, 3 = everyone
  else
    config.hit_graph_view_level = 0 # 0 = none, 1 = admin, 2 = editor, 3 = everyone
  end


end
