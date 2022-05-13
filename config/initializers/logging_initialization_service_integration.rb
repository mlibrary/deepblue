
require_relative "../../app/services/deepblue/logging_initialization_service"

Deepblue::LoggingIntializationService.setup do |config|

  config.suppress_active_support_logging = true
  config.suppress_active_support_logging_verbose = true
  config.suppress_blacklight_logging = false

  config.active_support_list_ids = false
  config.active_support_suppressed_ids = [ "ldp.active_fedora",
                                           "logger.active_fedora",
                                           # "render_collection.action_view",
                                           # "render_partial.action_view",
                                           # "render_template.action_view",
                                           "sql.active_record",
                                           "transmit_subscription_confirmation.action_cable",
                                           "transmit_subscription_rejection.action_cable" ]



end
