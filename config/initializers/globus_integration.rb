
Deepblue::GlobusIntegrationService.setup do |config|

  verbose_initialization = true

  # TODO: some of these are dependent and can be made readonly

  DOWNLOAD = 'download'.freeze
  LOCAL = 'local'.freeze
  PREP = 'prep'.freeze
  STAGING = 'staging'.freeze
  TEST = 'test'.freeze
  TESTING = 'testing'.freeze
  UNKNOWN = 'unknown'.freeze

  HOSTNAME_LOCAL = 'deepblue.local'.freeze
  HOSTNAME_PROD = 'deepblue.lib.umich.edu'.freeze
  HOSTNAME_TEST = 'test.deepblue.lib.umich.edu'.freeze
  HOSTNAME_TESTING = 'testing.deepblue.lib.umich.edu'.freeze
  HOSTNAME_STAGING = 'staging.deepblue.lib.umich.edu'.freeze

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
  puts "globus_dir=#{config.globus_dir}" if verbose_initialization if verbose_initialization
  config.globus_dir = Pathname.new config.globus_dir
  config.globus_download_dir = config.globus_dir.join DOWNLOAD
  config.globus_prep_dir = config.globus_dir.join PREP
  puts "globus init with hostname = #{DeepBlueDocs::Application.config.hostname}"
  case DeepBlueDocs::Application.config.hostname
  when HOSTNAME_PROD
    config.globus_download_dir = config.globus_dir.join DOWNLOAD
    config.globus_prep_dir = config.globus_dir.join PREP
  when HOSTNAME_TESTING
    config.globus_download_dir = config.globus_download_dir.join TESTING
    config.globus_prep_dir = config.globus_prep_dir.join TESTING
  when HOSTNAME_STAGING
    config.globus_download_dir = config.globus_download_dir.join STAGING
    config.globus_prep_dir = config.globus_prep_dir.join STAGING
  when HOSTNAME_TEST
    config.globus_download_dir = config.globus_dir.join( DOWNLOAD ).join( TEST )
    config.globus_prep_dir = config.globus_dir.join( PREP ).join( TEST )
  when HOSTNAME_LOCAL
    config.globus_download_dir = config.globus_dir.join( DOWNLOAD ).join( LOCAL )
    config.globus_prep_dir = config.globus_dir.join( PREP ).join( LOCAL )
  else
    config.globus_download_dir = config.globus_download_dir.join UNKNOWN
    config.globus_prep_dir = config.globus_prep_dir.join UNKNOWN
  end
  puts "globus_download_dir=#{config.globus_download_dir}" if verbose_initialization
  puts "globus_prep_dir=#{config.globus_prep_dir}" if verbose_initialization
  #if Rails.env.development? || Rails.env.test?
  FileUtils.mkdir_p config.globus_download_dir unless Dir.exist? config.globus_download_dir
  FileUtils.mkdir_p config.globus_prep_dir unless Dir.exist? config.globus_prep_dir
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

end
