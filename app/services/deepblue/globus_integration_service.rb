# frozen_string_literal: true

module Deepblue

  module GlobusIntegrationService

    @@_setup_ran = false

    @@globus_after_copy_job_ui_delay_seconds = 3
    @@globus_base_file_name
    @@globus_base_url
    @@globus_best_used_gt_size
    @@globus_best_used_gt_size_str
    @@globus_copy_file_group
    @@globus_copy_file_permissions
    @@globus_debug_delay_per_file_copy_job_seconds = 0
    @@globus_dir
    @@globus_download_dir
    @@globus_enabled = false
    @@globus_era_timestamp
    @@globus_era_token
    @@globus_prep_dir
    @@globus_restart_all_copy_jobs_quiet

    mattr_accessor :globus_after_copy_job_ui_delay_seconds,
                   :globus_base_file_name,
                   :globus_base_url,
                   :globus_best_used_gt_size,
                   :globus_best_used_gt_size_str,
                   :globus_copy_file_group,
                   :globus_copy_file_permissions,
                   :globus_debug_delay_per_file_copy_job_seconds,
                   :globus_dir,
                   :globus_download_dir,
                   :globus_prep_dir,
                   :globus_enabled,
                   :globus_era_timestamp,
                   :globus_era_token,
                   :globus_restart_all_copy_jobs_quiet

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    # TODO: some of these are dependent and can be made readonly

    # ## configure for Globus
    # # -- To enable Globus for development, create /deepbluedata-globus/download and /deepbluedata-globus/prep
    # config.globus_era_timestamp = Time.now.freeze
    # config.globus_era_token = config.globus_era_timestamp.to_s.freeze
    # if Rails.env.development?
    #   # TODO
    #   config.globus_dir = '/tmp/deepbluedata-globus'
    #   Dir.mkdir config.globus_dir unless Dir.exist? config.globus_dir
    # elsif Rails.env.test?
    #   config.globus_dir = '/tmp/deepbluedata-globus'
    #   Dir.mkdir config.globus_dir unless Dir.exist? config.globus_dir
    # else
    #   config.globus_dir = ENV['GLOBUS_DIR'] || '/deepbluedata-globus'
    # end
    # # puts "globus_dir=#{config.globus_dir}"
    # config.globus_dir = Pathname.new config.globus_dir
    # config.globus_download_dir = config.globus_dir.join 'download'
    # config.globus_prep_dir = config.globus_dir.join 'prep'
    # if Rails.env.test?
    #   Dir.mkdir config.globus_download_dir unless Dir.exist? config.globus_download_dir
    #   Dir.mkdir config.globus_prep_dir unless Dir.exist? config.globus_prep_dir
    # end
    # config.globus_enabled = true && Dir.exist?( config.globus_download_dir ) && Dir.exist?( config.globus_prep_dir )
    # config.globus_base_file_name = "DeepBlueData_"
    # config.globus_base_url = 'https://app.globus.org/file-manager?origin_id=99d8c648-a9ff-11e7-aedd-22000a92523b&origin_path=%2Fdownload%2F'
    # config.globus_restart_all_copy_jobs_quiet = true
    # config.globus_debug_delay_per_file_copy_job_seconds = 0
    # config.globus_after_copy_job_ui_delay_seconds = 3
    # if Rails.env.production?
    #   config.globus_copy_file_group = "dbdglobus"
    # else
    #   config.globus_copy_file_group = nil
    # end
    # config.globus_copy_file_permissions = "u=rw,g=rw,o=r"
    # config.globus_best_used_gt_size = 3.gigabytes
    # config.globus_best_used_gt_size_str = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(config.globus_best_used_gt_size, {})

  end

end
