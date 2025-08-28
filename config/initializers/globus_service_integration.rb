
Deepblue::GlobusIntegrationService.setup do |config|

  verbose_initialization = false && Rails.configuration.program_name != 'resque-pool'

  puts ">>>>> globus initalization starting..." if verbose_initialization

  config.globus_integration_service_debug_verbose = false
  config.globus_dashboard_controller_debug_verbose = false
  config.globus_dashboard_presenter_debug_verbose = false

  new_globus_directories = true

  # TODO: some of these are dependent and can be made readonly

  config.globus_use_data_den = false # the new globus world as of 2025 --> use Feature Flipflop.globus_use_data_den
  # config.globus_enabled # see below
  config.globus_always_available = true # set to true to force globus to show in ui

  ## configure for Globus
  # -- To enable Globus for development, create /deepbluedata-globus/download and /deepbluedata-globus/prep
  config.globus_era_timestamp = Time.now.freeze
  config.globus_era_token = config.globus_era_timestamp.to_s.freeze
  if Rails.env.development?
    config.globus_dir = './data/globus'
    FileUtils.mkdir_p config.globus_dir unless Dir.exist? config.globus_dir
  elsif Rails.env.test?
    config.globus_dir = './data/globus'
    FileUtils.mkdir_p config.globus_dir unless Dir.exist? config.globus_dir
  elsif new_globus_directories
    config.globus_dir = '/deepbluedata-dataden'
  else
    config.globus_dir = '/deepbluedata-globus'
  end
  puts "globus_dir=#{config.globus_dir}" if verbose_initialization
  config.globus_dir = Pathname.new config.globus_dir
  config.globus_dir_modifier = ''
  config.globus_download_dir = config.globus_dir.join ::Deepblue::InitializationConstants::DOWNLOAD
  config.globus_prep_dir = config.globus_dir.join ::Deepblue::InitializationConstants::PREP
  config.globus_upload_dir = config.globus_dir.join ::Deepblue::InitializationConstants::UPLOAD
  puts "globus init with hostname = #{Rails.configuration.hostname}" if verbose_initialization
  puts "globus_always_available=#{config.globus_always_available}"
  case Rails.configuration.hostname
  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
    config.globus_download_dir = config.globus_dir.join ::Deepblue::InitializationConstants::DOWNLOAD
    config.globus_prep_dir = config.globus_dir.join ::Deepblue::InitializationConstants::PREP
    config.globus_upload_dir = config.globus_dir.join ::Deepblue::InitializationConstants::UPLOAD
    config.globus_enabled = true
  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::TESTING
    config.globus_download_dir = config.globus_download_dir.join ::Deepblue::InitializationConstants::TESTING
    config.globus_prep_dir = config.globus_prep_dir.join ::Deepblue::InitializationConstants::TESTING
    config.globus_upload_dir = config.globus_dir.join ::Deepblue::InitializationConstants::UPLOAD
    config.globus_enabled = config.globus_always_available
  when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::STAGING
    config.globus_download_dir = config.globus_download_dir.join ::Deepblue::InitializationConstants::STAGING
    config.globus_prep_dir = config.globus_prep_dir.join ::Deepblue::InitializationConstants::STAGING
    config.globus_upload_dir = config.globus_dir.join ::Deepblue::InitializationConstants::UPLOAD
    config.globus_enabled = config.globus_always_available
  when ::Deepblue::InitializationConstants::HOSTNAME_TEST
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::TEST
    config.globus_download_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::DOWNLOAD,
                                                         ::Deepblue::InitializationConstants::TEST )
    config.globus_prep_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::PREP,
                                                     ::Deepblue::InitializationConstants::TEST )
    config.globus_upload_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::UPLOAD,
                                                     ::Deepblue::InitializationConstants::TEST )
    config.globus_enabled = config.globus_always_available
  when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::LOCAL
    config.globus_download_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::DOWNLOAD )
    config.globus_prep_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::PREP )
    config.globus_upload_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::UPLOAD )
    config.globus_enabled = config.globus_always_available
  else
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::UNKNOWN
    config.globus_download_dir = config.globus_download_dir.join ::Deepblue::InitializationConstants::UNKNOWN
    config.globus_prep_dir = config.globus_prep_dir.join ::Deepblue::InitializationConstants::UNKNOWN
    config.globus_upload_dir = config.globus_dir.join ::Deepblue::InitializationConstants::UNKNOWN
    config.globus_enabled = config.globus_always_available
  end
  # puts "globus_download_dir=#{config.globus_download_dir}" if verbose_initialization
  # puts "globus_prep_dir=#{config.globus_prep_dir}" if verbose_initialization
  # puts "globus_upload_dir=#{config.globus_upload_dir}" if verbose_initialization
  # puts "globus_enabled=#{config.globus_enabled}" if verbose_initialization
  # puts "globus_export=#{config.globus_export}" if verbose_initialization

  puts "globus_use_data_den=#{config.globus_use_data_den}" if verbose_initialization
  if config.globus_use_data_den
    config.globus_export = false
  else
    config.globus_export = config.globus_enabled && Dir.exist?( config.globus_download_dir ) && Dir.exist?( config.globus_prep_dir )
    config.globus_base_file_name = "DeepBlueData_"
  end

  puts "globus final values:" if verbose_initialization
  puts "globus_download_dir=#{config.globus_download_dir}" if verbose_initialization

  if config.globus_export
    begin
      FileUtils.mkdir_p config.globus_download_dir unless Dir.exist? config.globus_download_dir
      FileUtils.mkdir_p config.globus_prep_dir unless Dir.exist? config.globus_prep_dir
    rescue Exception => e # rubocop:disable Lint/RescueException
      # ignore
    end
    config.globus_restart_all_copy_jobs_quiet = true
    config.globus_debug_delay_per_file_copy_job_seconds = 0
    config.globus_after_copy_job_ui_delay_seconds = 3
    if Rails.env.production?
      config.globus_copy_file_group = "dbdglobus"
    else
      config.globus_copy_file_group = nil
    end
    config.globus_copy_file_permissions = "u=rw,g=rw,o=r"
    config.globus_best_used_gt_size = 3.gigabytes
    config.globus_best_used_gt_size_str = ::ConfigHelper.human_readable_size(config.globus_best_used_gt_size)
    if verbose_initialization
      puts "globus_restart_all_copy_jobs_quiet=#{config.globus_restart_all_copy_jobs_quiet}"
      puts "globus_debug_delay_per_file_copy_job_seconds=#{config.globus_debug_delay_per_file_copy_job_seconds}"
      puts "globus_after_copy_job_ui_delay_seconds=#{config.globus_after_copy_job_ui_delay_seconds}"
      puts "globus_copy_file_permissions=#{config.globus_copy_file_permissions}"
      puts "globus_best_used_gt_size=#{config.globus_best_used_gt_size}"
      puts "globus_best_used_gt_size_str=#{config.globus_best_used_gt_size_str}"
    end
  end

  config.globus_base_url_legacy = 'https://app.globus.org/file-manager?origin_id=4db576d9-f052-4494-93eb-1d6c0008f358&origin_path=%2F'
  config.globus_base_url_data_den = 'https://app.globus.org/file-manager?origin_id=cc387c09-b0e5-422b-a384-0d96e7ffdc73&origin_path='
  config.globus_bounce_external_link_off_server = true

  if Rails.env.development?
    config.globus_dashboard_display_all_works = true
    config.globus_dashboard_display_report = false
    # config.globus_debug_delay_per_file_copy_job_seconds = 30
    config.globus_dashboard_controller_debug_verbose = false

    config.globus_default_generate_error_on_copy = false
    config.globus_default_delay_per_file_seconds_on_copy = 0
  else
    config.globus_dashboard_display_all_works = false
    config.globus_dashboard_display_report = false
  end
  if verbose_initialization
    puts "globus_allow_legacy=#{config.globus_allow_legacy}"
    puts "globus_download_dir=#{config.globus_download_dir}"
    puts "globus_prep_dir=#{config.globus_prep_dir}"
    puts "globus_upload_dir=#{config.globus_upload_dir}"
    puts "globus_export=#{config.globus_export}"
    puts "globus_base_file_name=#{config.globus_base_file_name}"
    puts "globus_base_url_data_den=#{config.globus_base_url_legacy}"
    puts "globus_base_url_legacy=#{config.globus_base_url_legacy}"
    puts "globus_dashboard_display_all_works=#{config.globus_dashboard_display_all_works}"
    puts "globus_dashboard_display_report=#{config.globus_dashboard_display_report}"
    puts "globus_dashboard_controller_debug_verbose=#{config.globus_dashboard_controller_debug_verbose}"
    puts "globus_always_available=#{config.globus_always_available}"
    puts "globus_use_data_den=#{config.globus_use_data_den}"
    puts "globus_enabled=#{config.globus_enabled}"
  end
  puts ">>>>> globus initalization finished." if verbose_initialization

end
