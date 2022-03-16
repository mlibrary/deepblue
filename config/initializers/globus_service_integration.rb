
Deepblue::GlobusIntegrationService.setup do |config|

  verbose_initialization = false && Rails.configuration.program_name != 'resque-pool'

  config.globus_integration_service_debug_verbose = false

  # TODO: some of these are dependent and can be made readonly

  ## configure for Globus
  # -- To enable Globus for development, create /deepbluedata-globus/download and /deepbluedata-globus/prep
  config.globus_era_timestamp = Time.now.freeze
  config.globus_era_token = config.globus_era_timestamp.to_s.freeze
  if Rails.env.development?
    # TODO
    config.globus_dir = '/tmp/deepbluedata-globus'
    FileUtils.mkdir_p config.globus_dir unless Dir.exist? config.globus_dir
  elsif Rails.env.test?
    config.globus_dir = '/tmp/deepbluedata-globus'
    FileUtils.mkdir_p config.globus_dir unless Dir.exist? config.globus_dir
  else
    config.globus_dir = '/deepbluedata-globus'
  end
  puts "globus_dir=#{config.globus_dir}" if verbose_initialization
  config.globus_dir = Pathname.new config.globus_dir
  config.globus_dir_modifier = ''
  config.globus_download_dir = config.globus_dir.join ::Deepblue::InitializationConstants::DOWNLOAD
  config.globus_prep_dir = config.globus_dir.join ::Deepblue::InitializationConstants::PREP
  puts "globus init with hostname = #{DeepBlueDocs::Application.config.hostname}" if verbose_initialization
  case DeepBlueDocs::Application.config.hostname
  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
    config.globus_download_dir = config.globus_dir.join ::Deepblue::InitializationConstants::DOWNLOAD
    config.globus_prep_dir = config.globus_dir.join ::Deepblue::InitializationConstants::PREP
  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::TESTING
    config.globus_download_dir = config.globus_download_dir.join ::Deepblue::InitializationConstants::TESTING
    config.globus_prep_dir = config.globus_prep_dir.join ::Deepblue::InitializationConstants::TESTING
  when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::STAGING
    config.globus_download_dir = config.globus_download_dir.join ::Deepblue::InitializationConstants::STAGING
    config.globus_prep_dir = config.globus_prep_dir.join ::Deepblue::InitializationConstants::STAGING
  when ::Deepblue::InitializationConstants::HOSTNAME_TEST
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::TEST
    config.globus_download_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::DOWNLOAD,
                                                         ::Deepblue::InitializationConstants::TEST )
    config.globus_prep_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::PREP,
                                                     ::Deepblue::InitializationConstants::TEST )
  when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::LOCAL
    config.globus_download_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::DOWNLOAD,
                                                         ::Deepblue::InitializationConstants::LOCAL )
    config.globus_prep_dir = config.globus_dir.join( ::Deepblue::InitializationConstants::PREP,
                                                     ::Deepblue::InitializationConstants::LOCAL )
  else
    config.globus_dir_modifier = ::Deepblue::InitializationConstants::UNKNOWN
    config.globus_download_dir = config.globus_download_dir.join ::Deepblue::InitializationConstants::UNKNOWN
    config.globus_prep_dir = config.globus_prep_dir.join ::Deepblue::InitializationConstants::UNKNOWN
  end
  puts "globus_download_dir=#{config.globus_download_dir}" if verbose_initialization
  puts "globus_prep_dir=#{config.globus_prep_dir}" if verbose_initialization
  #if Rails.env.development? || Rails.env.test?
  begin
    FileUtils.mkdir_p config.globus_download_dir unless Dir.exist? config.globus_download_dir
    FileUtils.mkdir_p config.globus_prep_dir unless Dir.exist? config.globus_prep_dir
  rescue Exception => e # rubocop:disable Lint/RescueException
    # ignore
  end
  #end
  config.globus_enabled = true && Dir.exist?( config.globus_download_dir ) && Dir.exist?( config.globus_prep_dir )
  puts "globus_enabled=#{config.globus_enabled}" if verbose_initialization
  config.globus_base_file_name = "DeepBlueData_"
  puts "globus_base_file_name=#{config.globus_base_file_name}" if verbose_initialization
  config.globus_base_url = 'https://app.globus.org/file-manager?origin_id=99d8c648-a9ff-11e7-aedd-22000a92523b&origin_path=%2Fdownload%2F'
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
  config.globus_best_used_gt_size_str = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(config.globus_best_used_gt_size, {})

  config.globus_bounce_external_link_off_server = true

end
