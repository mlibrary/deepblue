
require_relative "../../app/services/deepblue/logging_initialization_service"

Deepblue::LoggingIntializationService.setup do |config|

  config.suppress_active_support_logging = true
  config.suppress_active_support_logging_active_view_render = false
  config.suppress_active_support_logging_verbose = true

  config.suppress_blacklight_logging = true

end
