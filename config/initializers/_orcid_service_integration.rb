# frozen_string_literal: true

# NOTE: naming this "" forces it to process first. Otherwise, something else intervenes and won't be processed.

Hyrax::OrcidIntegrationService.setup do |config|

  puts "config - ::Hyrax::OrcidIntegrationService.setup..." if Hyrax::OrcidIntegrationService::HYRAX_INTEGRATION_SERVICE_SETUP_VERBOSE

  config.hyrax_orcid_debug_verbose                   = false
  config.hyrax_orcid_actors_debug_verbose            = false
  config.hyrax_orcid_helper_debug_verbose            = false
  config.hyrax_orcid_jobs_debug_verbose              = false
  config.hyrax_orcid_presenter_debug_verbose         = false
  config.hyrax_orcid_publisher_service_debug_verbose = false
  config.hyrax_orcid_strategy_debug_verbose          = false
  config.hyrax_orcid_user_behavior_debug_verbose     = false
  config.hyrax_orcid_views_debug_verbose             = false
  config.hyrax_orcid_extractor_debug_verbose         = false

  config.enable_work_syncronization = true

  puts "config - ::Hyrax::OrcidIntegrationService.setup finished" if Hyrax::OrcidIntegrationService::HYRAX_INTEGRATION_SERVICE_SETUP_VERBOSE

end
