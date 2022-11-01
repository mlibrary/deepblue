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

    mattr_accessor :globus_after_copy_job_ui_delay_seconds,       default: 3
    mattr_accessor :globus_base_file_name,                        default: "DeepBlueData_"
    mattr_accessor :globus_base_url,                              default: 'https://app.globus.org/file-manager?origin_id=99d8c648-a9ff-11e7-aedd-22000a92523b&origin_path=%2Fdownload%2F'
    mattr_accessor :globus_best_used_gt_size,                     default: 3.gigabytes
    mattr_accessor :globus_best_used_gt_size_str,                 default: ::ConfigHelper.human_readable_size(globus_best_used_gt_size)
    mattr_accessor :globus_bounce_external_link_off_server,       default: true
    mattr_accessor :globus_copy_file_group,                       default: nil
    mattr_accessor :globus_copy_file_permissions,                 default: "u=rw,g=rw,o=r"
    mattr_accessor :globus_dashboard_display_all_works,           default: false
    mattr_accessor :globus_dashboard_display_report,              default: false
    mattr_accessor :globus_debug_delay_per_file_copy_job_seconds, default: 0
    mattr_accessor :globus_dir,                                   default: './data/globus'
    mattr_accessor :globus_dir_modifier,                          default: ''
    mattr_accessor :globus_download_dir,                          default: File.join( globus_dir,
                                                                        ::Deepblue::InitializationConstants::DOWNLOAD )
    mattr_accessor :globus_enabled,                               default: false
    mattr_accessor :globus_era_timestamp
    mattr_accessor :globus_era_token
    mattr_accessor :globus_prep_dir,                             default: File.join( globus_dir,
                                                                         ::Deepblue::InitializationConstants::PREP )
    mattr_accessor :globus_restart_all_copy_jobs_quiet,          default: true

    def self.globus_int_srv()
      puts "globus_int_srv"
    end

    def self.globus_status( include_disk_usage: true, msg_handler: )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ]  if msg_handler.debug_verbose
      rv = GlobusStatus.new( include_disk_usage: include_disk_usage, msg_handler: msg_handler )
      rv.populate
      return rv
    end

    def self.globus_status_report( msg_handler:, errors_report: false )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ]  if msg_handler.debug_verbose
      rv = GlobusStatus.new( msg_handler: msg_handler, skip_ready: errors_report, auto_populate: false )
      rv.populate
      return rv.reporter
    end

    def self.globus_job_complete_file( concern_id: )
      GlobusJob.target_file_name_env( ::Deepblue::GlobusIntegrationService.globus_prep_dir,
                                      'restarted',
                                      GlobusJob.target_base_name( concern_id ) )
    end

    def self.globus_job_complete?( concern_id:, debug_verbose: globus_integration_service_debug_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "concern_id=#{concern_id}",
                                             "" ] if debug_verbose
      file = globus_job_complete_file( concern_id: concern_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file=#{file}",
                                             "" ] if debug_verbose
      return false unless File.exist? file
      last_complete_time = last_complete_time file
      token_time = ::GlobusJob.era_token_time
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "token_time.class.name=#{token_time.class.name}",
                                             "token_time=#{token_time} <= last_complete_time=#{last_complete_time}",
                                             "" ] if debug_verbose
      token_time <= last_complete_time
    end

    def self.last_complete_time( file )
      File.birthtime file
    end

  end

end
