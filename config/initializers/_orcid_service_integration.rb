# frozen_string_literal: true

puts "Hyrax::OrcidIntegrationService.setup do |config|"

Hyrax::OrcidIntegrationService.setup do |config|

  puts "config - ::Hyrax::OrcidIntegrationService.setup..."

  config.hyrax_orcid_debug_verbose                   = false
  config.hyrax_orcid_actors_debug_verbose            = true
  config.hyrax_orcid_jobs_debug_verbose              = true
  config.hyrax_orcid_publisher_service_debug_verbose = true
  config.hyrax_orcid_strategy_debug_verbose          = true
  config.hyrax_orcid_user_behavior_debug_verbose     = true
  config.hyrax_orcid_views_debug_verbose             = true

  puts "config - ::Hyrax::OrcidIntegrationService.setup finished"

end
