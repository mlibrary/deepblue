
Deepblue::IngestIntegrationService.setup do |config|

  config.characterization_service_verbose = false

  config.characterize_excluded_ext_set = { '.csv' => 'text/plain' }.freeze # , '.nc' => 'text/plain' }.freeze
  config.characterize_enforced_mime_type = { '.csv' => 'text/csv' }.freeze # , '.nc' => 'text/plain' }.freeze

  config.characterize_mime_type_ext_mismatch = { 'text/plain' => '.html' }.freeze
  config.characterize_mime_type_ext_mismatch_fix = { ".html" => 'text/html' }.freeze

  config.ingest_append_ui_allowed_base_directories = [ "/deepbluedata-prep",
                                                       "/Volumes/ulib-dbd-prep" ]

  config.ingest_append_queue_name = 'ingest'

end
