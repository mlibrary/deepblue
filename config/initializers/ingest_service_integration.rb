
Deepblue::IngestIntegrationService.setup do |config|

  config.characterization_service_verbose = false

  config.characterize_excluded_ext_set = { '.csv' => 'text/plain' }.freeze # , '.nc' => 'text/plain' }.freeze
  config.characterize_enforced_mime_type = { '.csv' => 'text/csv' }.freeze # , '.nc' => 'text/plain' }.freeze

  config.characterize_mime_type_ext_mismatch = { 'text/plain' => '.html' }.freeze
  config.characterize_mime_type_ext_mismatch_fix = { ".html" => 'text/html' }.freeze

  config.ingest_append_queue_name = 'batch_update'
  allowed_dirs = [ "/deepbluedata-prep" ]
  if Rails.env.development?
    allowed_dirs << File.join( Dir.home, 'Downloads' ).to_s
    allowed_dirs << Rails.application.root.join( 'data' ).to_s
    if Dir.exists? "/Volumes/ulib-dbd-prep"
      allowed_dirs << "/Volumes/ulib-dbd-prep"
      config.ingest_script_dir = "/Volumes/ulib-dbd-prep/scripts"
    else
      allowed_dirs << "/tmp/deepbluedata-prep"
      config.ingest_script_dir = "/tmp/deepbluedata-prep/scripts"
    end
  elsif Rails.env.test?
    config.ingest_script_dir = '/tmp/deepbluedata-prep/scripts'
  else
    config.ingest_script_dir = '/deepbluedata-prep/scripts'
  end
  config.ingest_append_ui_allowed_base_directories = allowed_dirs
  case DeepBlueDocs::Application.config.hostname
  when HOSTNAME_PROD
    config.ingest_script_dir = File.join config.ingest_script_dir, 'production'
  when HOSTNAME_TESTING
    config.ingest_script_dir = File.join config.ingest_script_dir, 'testing'
  when HOSTNAME_STAGING
    config.ingest_script_dir = File.join config.ingest_script_dir, 'staging'
  when HOSTNAME_TEST
    config.ingest_script_dir = File.join config.ingest_script_dir, 'test'
  when HOSTNAME_LOCAL
    config.ingest_script_dir = File.join config.ingest_script_dir, 'local'
  else
    config.ingest_script_dir = File.join config.ingest_script_dir, 'unknown'
  end
  FileUtils.mkdir_p config.ingest_script_dir unless Dir.exist? config.ingest_script_dir

  config.ingest_append_ui_allow_scripts_to_run = Dir.exist? config.ingest_script_dir

end
