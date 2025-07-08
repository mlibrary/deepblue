# frozen_string_literal: true

require_relative '../../helpers/config_helper'

module Deepblue

  module GlobusIntegrationService

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :globus_integration_service_debug_verbose,  default: false
    mattr_accessor :globus_dashboard_controller_debug_verbose, default: false
    mattr_accessor :globus_dashboard_presenter_debug_verbose,  default: false

    mattr_accessor :globus_use_data_den,                       default: false  # the new globus world as of 2025
    mattr_accessor :globus_enabled,                            default: false
    mattr_accessor :globus_always_available,                   default: true # set to true to force globus to show in ui
    mattr_accessor :globus_export,                             default: false # old globus export mechanism

    mattr_accessor :globus_after_copy_job_ui_delay_seconds,       default: 3
    mattr_accessor :globus_base_file_name,                        default: "DeepBlueData_"
    mattr_accessor :globus_base_url,
                   default: 'https://app.globus.org/file-manager?origin_id=4db576d9-f052-4494-93eb-1d6c0008f358&origin_path=%2F'
                   # default: 'https://app.globus.org/file-manager?origin_id=99d8c648-a9ff-11e7-aedd-22000a92523b&origin_path=%2Fdownload%2F'
    mattr_accessor :globus_best_used_gt_size,                     default: 3.gigabytes
    mattr_accessor :globus_best_used_gt_size_str,
                   default: ::ConfigHelper.human_readable_size(globus_best_used_gt_size)
    mattr_accessor :globus_bounce_external_link_off_server,       default: true
    mattr_accessor :globus_copy_file_group,                       default: nil
    mattr_accessor :globus_copy_file_permissions,                 default: "u=rw,g=rw,o=r"
    mattr_accessor :globus_dashboard_display_all_works,           default: false
    mattr_accessor :globus_dashboard_display_report,              default: false
    mattr_accessor :globus_debug_delay_per_file_copy_job_seconds, default: 0
    mattr_accessor :globus_dir,                                   default: './data/globus'
    mattr_accessor :globus_dir_modifier,                          default: ''
    mattr_accessor :globus_download_dir,
                   default: File.join( globus_dir, ::Deepblue::InitializationConstants::DOWNLOAD )
    mattr_accessor :globus_era_timestamp
    mattr_accessor :globus_era_token
    mattr_accessor :globus_prep_dir,
                   default: File.join( globus_dir, ::Deepblue::InitializationConstants::PREP )
    mattr_accessor :globus_upload_dir,
                   default: File.join( globus_dir, ::Deepblue::InitializationConstants::UPLOAD )
    mattr_accessor :globus_restart_all_copy_jobs_quiet,          default: true

    mattr_accessor :globus_default_generate_error_on_copy,       default: false
    mattr_accessor :globus_default_delay_per_file_seconds_on_copy, default: 0

    def self.globus_int_srv()
      puts "globus_int_srv"
    end

  end

end
