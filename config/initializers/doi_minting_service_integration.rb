
Deepblue::DoiMintingService.setup do |config|

  ## configure doi minting service

  config.doi_minting_service_debug_verbose = false

  config.doi_minting_service_integration_hostnames = [ 'deepblue.local',
                                        'testing.deepblue.lib.umich.edu',
                                        'staging.deepblue.lib.umich.edu',
                                        'deepblue.lib.umich.edu' ].freeze

  config.doi_minting_service_integration_hostnames_prod = [ 'deepblue.lib.umich.edu',
                                             'testing.deepblue.lib.umich.edu' ].freeze
  config.doi_minting_service_integration_enabled = config.doi_minting_service_integration_hostnames.include?(
      DeepBlueDocs::Application.config.hostname )
  config.doi_mint_on_publication_event = config.doi_minting_service_integration_enabled && false


  config.doi_publisher_name = "University of Michigan".freeze
  config.doi_resource_type = "Dataset".freeze
  config.doi_resource_types = [ "Dataset", "Fileset" ].freeze



  config.doi_minting_2021_service_enabled = true

  config.test_base_url = "https://api.test.datacite.org/"
  config.test_mds_base_url = "https://mds.test.datacite.org/"
  config.production_base_url = "https://api.datacite.org/"
  config.production_mds_base_url = "https://mds.datacite.org/"


end
