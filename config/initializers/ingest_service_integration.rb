
Deepblue::IngestIntegrationService.setup do |config|

  INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE = false

  config.characterization_service_verbose = false

  config.characterize_excluded_ext_set = { '.csv' => 'text/plain' }.freeze # , '.nc' => 'text/plain' }.freeze
  config.characterize_enforced_mime_type = { '.csv' => 'text/csv' }.freeze # , '.nc' => 'text/plain' }.freeze

  config.characterize_mime_type_ext_mismatch = { 'text/plain' => '.html' }.freeze
  config.characterize_mime_type_ext_mismatch_fix = { ".html" => 'text/html' }.freeze

  config.ingest_append_queue_name = :default
  allowed_dirs = [ "/deepbluedata-prep", "/deepbluedata-globus" ]
  if Rails.env.development?
    allowed_dirs << File.join( Dir.home, 'Downloads' ).to_s
    allowed_dirs << Rails.application.root.join( 'data' ).to_s
    if Dir.exists? "/Volumes/ulib-dbd-prep"
      allowed_dirs << "/Volumes/ulib-dbd-prep"
      config.ingest_script_dir = "/Volumes/ulib-dbd-prep/scripts"
      config.deepbluedata_prep = "/Volumes/ulib-dbd-prep"
    else
      allowed_dirs << "/tmp/deepbluedata-prep"
      config.ingest_script_dir = "/tmp/deepbluedata-prep/scripts"
      config.deepbluedata_prep = "/tmp/deepbluedata-prep"
    end
  elsif Rails.env.test?
    config.ingest_script_dir = '/tmp/deepbluedata-prep/scripts'
    config.deepbluedata_prep = '/tmp/deepbluedata-prep'
  else
    config.ingest_script_dir = '/deepbluedata-prep/scripts'
    config.deepbluedata_prep = '/deepbluedata-prep'
  end
  config.ingest_append_ui_allowed_base_directories = allowed_dirs
  ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "DeepBlueDocs::Application.config.hostname = #{DeepBlueDocs::Application.config.hostname}",
                                         "" ] if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  case DeepBlueDocs::Application.config.hostname
  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
    config.ingest_script_dir = File.join config.ingest_script_dir, ::Deepblue::InitializationConstants::PRODUCTION
  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
    config.ingest_script_dir = File.join config.ingest_script_dir, ::Deepblue::InitializationConstants::TESTING
  when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
    config.ingest_script_dir = File.join config.ingest_script_dir, ::Deepblue::InitializationConstants::STAGING
  when ::Deepblue::InitializationConstants::HOSTNAME_TEST
    config.ingest_script_dir = File.join config.ingest_script_dir, ::Deepblue::InitializationConstants::TEST
  when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
    config.ingest_script_dir = File.join config.ingest_script_dir, ::Deepblue::InitializationConstants::LOCAL
  else
    config.ingest_script_dir = File.join config.ingest_script_dir, ::Deepblue::InitializationConstants::UNKNOWN
  end
  ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "config.ingest_script_dir = #{config.ingest_script_dir}",
                                         "" ] if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE
  ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "Dir.exist? #{config.ingest_script_dir} #{Dir.exist? config.ingest_script_dir}",
                                         "" ] if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  begin
    FileUtils.mkdir_p config.ingest_script_dir unless Dir.exist? config.ingest_script_dir
  rescue Exception => e # rubocop:disable Lint/RescueException
    # this will fail during moku build, so catch and ignore
  end

  ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "Dir.exist? #{config.ingest_script_dir} #{Dir.exist? config.ingest_script_dir}",
                                         "" ] if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  config.ingest_append_ui_allow_scripts_to_run = Dir.exist? config.ingest_script_dir

  ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "config.ingest_append_ui_allow_scripts_to_run=#{config.ingest_append_ui_allow_scripts_to_run}",
                                         "" ] if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

end
