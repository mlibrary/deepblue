
Deepblue::IngestIntegrationService.setup do |config|

  INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE = false

  puts "Ingest integration service setup starting..." if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  config.abstract_ingest_job_debug_verbose           = false
  config.add_file_to_file_set_debug_verbose          = false
  config.attach_files_to_work_job_debug_verbose      = false
  config.characterize_job_debug_verbose              = false
  config.characterization_service_debug_verbose      = false
  config.ingest_append_content_service_debug_verbose = false
  config.ingest_content_service_debug_verbose        = false
  config.create_derivatives_job_debug_verbose        = false
  config.ingest_helper_debug_verbose                 = false
  config.ingest_append_job_debug_verbose             = false
  config.ingest_append_script_job_debug_verbose      = false
  config.ingest_append_script_monitor_job_debug_verbose = false
  config.ingest_append_scripts_controller_behavior_debug_verbose = false
  config.ingest_job_debug_verbose                    = false
  config.ingest_job_status_debug_verbose             = false
  config.ingest_script_debug_verbose                 = false
  config.ingest_script_job_debug_verbose             = false
  config.multiple_ingest_scripts_job_debug_verbose   = false
  config.new_content_service_debug_verbose           = false
  config.report_task_job_debug_verbose               = false

  config.ingest_script_tracking_dir_base             = Rails.root.join('tmp', 'scripts')
  config.ingest_script_tracking_dir_expand_id        = true


  config.characterize_excluded_ext_set = { '.csv' => 'text/plain' }.freeze # , '.nc' => 'text/plain' }.freeze
  config.characterize_enforced_mime_type = { '.csv' => 'text/csv' }.freeze # , '.nc' => 'text/plain' }.freeze

  config.characterize_mime_type_ext_mismatch = { 'text/plain' => '.html' }.freeze
  config.characterize_mime_type_ext_mismatch_fix = { ".html" => 'text/html' }.freeze

  config.ingest_append_queue_name = :default
  allowed_dirs = [ "/deepbluedata-prep", "/deepbluedata-globus", "./data/" ]
  if Rails.env.development?
    allowed_dirs << File.join( Dir.home, 'Documents' ).to_s
    allowed_dirs << File.join( Dir.home, 'Downloads' ).to_s
    allowed_dirs << Rails.application.root.join( 'data' ).to_s
    config.ingest_script_dir = Rails.root.join('data', 'scripts')
    FileUtils.mkdir_p config.ingest_script_dir unless Dir.exist? config.ingest_script_dir
    if Dir.exists? "/Volumes/ulib-dbd-prep"
      allowed_dirs << "/Volumes/ulib-dbd-prep"
      config.deepbluedata_prep = "/Volumes/ulib-dbd-prep"
    else
      allowed_dirs << "/tmp/deepbluedata-prep"
      config.deepbluedata_prep = "/tmp/deepbluedata-prep"
    end
  elsif Rails.env.test?
    config.ingest_script_dir = '/tmp/deepbluedata-prep/scripts'
    config.deepbluedata_prep = '/tmp/deepbluedata-prep'
  else
    config.ingest_script_dir = '/deepbluedata-prep/scripts'
    config.deepbluedata_prep = '/deepbluedata-prep'
  end
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "allowed_dirs=#{allowed_dirs.pretty_inspect}",
                                         "" ], bold_puts: true if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE
  config.ingest_append_ui_allowed_base_directories = allowed_dirs
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
       ::Deepblue::LoggingHelper.called_from,
       "config.ingest_append_ui_allowed_base_directories=#{config.ingest_append_ui_allowed_base_directories.pretty_inspect}",
       "" ], bold_puts: true if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE
  config.ingest_allowed_path_prefixes = allowed_dirs
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "Rails.configuration.hostname = #{Rails.configuration.hostname}",
                                         "" ], bold_puts: true if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  case Rails.configuration.hostname
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
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "config.ingest_script_dir = #{config.ingest_script_dir}",
                                         "" ], bold_puts: true if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "Dir.exist? #{config.ingest_script_dir} #{Dir.exist? config.ingest_script_dir}",
                                         "" ], bold_puts: true if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  begin
    FileUtils.mkdir_p config.ingest_script_dir unless Dir.exist? config.ingest_script_dir
  rescue Exception => e # rubocop:disable Lint/RescueException
    # this will fail during moku build, so catch and ignore
  end

  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                       ::Deepblue::LoggingHelper.called_from,
                                       "Dir.exist? #{config.ingest_script_dir} #{Dir.exist? config.ingest_script_dir}",
                                       "" ], bold_puts: true if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  config.ingest_append_ui_allow_scripts_to_run = Dir.exist? config.ingest_script_dir

  config.ingest_append_script_allow_delete_any_script = true

  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                         ::Deepblue::LoggingHelper.called_from,
                         "config.ingest_append_ui_allow_scripts_to_run=#{config.ingest_append_ui_allow_scripts_to_run}",
                         "" ], bold_puts: true if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  config.ingest_append_script_job_verbose = false
  config.ingest_append_script_monitor_job_verbose = false
  config.add_job_json_to_ingest_script = false
  config.ingest_append_script_max_appends = 20
  config.ingest_append_script_max_restarts_base = 4
  config.ingest_append_script_monitor_wait_duration = 2

  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
             ::Deepblue::LoggingHelper.called_from,
             "config.ingest_append_script_monitor_job_verbose=#{config.ingest_append_script_monitor_job_verbose}",
             "config.add_job_json_to_ingest_script=#{config.add_job_json_to_ingest_script}",
             "config.ingest_append_script_max_appends=#{config.ingest_append_script_max_appends}",
             "config.ingest_append_script_max_restarts_base=#{config.ingest_append_script_max_restarts_base}",
             "config.ingest_append_script_monitor_wait_duration=#{config.ingest_append_script_monitor_wait_duration}",
             "" ], bold_puts: true if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  puts config.ingest_append_ui_allowed_base_directories.pretty_inspect if INGEST_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE
  # puts ::Deepblue::IngestIntegrationService.ingest_append_ui_allowed_base_directories.pretty_inspect
  puts "Finished ingest integration service configuration."
end
