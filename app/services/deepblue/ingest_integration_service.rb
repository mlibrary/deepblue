# frozen_string_literal: true

module Deepblue

  module IngestIntegrationService

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

    mattr_accessor :abstract_ingest_job_debug_verbose,                default: false
    mattr_accessor :add_file_to_file_set_debug_verbose,               default: false
    mattr_accessor :attach_files_to_work_job_debug_verbose,           default: false
    mattr_accessor :characterize_job_debug_verbose,                   default: false
    mattr_accessor :create_derivatives_job_debug_verbose,             default: false
    mattr_accessor :ingest_append_content_service_debug_verbose,      default: false
    mattr_accessor :ingest_content_service_debug_verbose,             default: false
    mattr_accessor :ingest_helper_debug_verbose,                      default: false
    mattr_accessor :ingest_append_job_debug_verbose,                  default: false
    mattr_accessor :ingest_append_scripts_controller_behavior_debug_verbose, default: false
    mattr_accessor :ingest_append_script_job_debug_verbose,           default: false
    mattr_accessor :ingest_job_debug_verbose,                         default: false
    mattr_accessor :ingest_job_status_debug_verbose,                  default: false
    mattr_accessor :ingest_script_debug_verbose,                      default: false
    mattr_accessor :ingest_script_job_debug_verbose,                  default: false
    mattr_accessor :multiple_ingest_scripts_job_debug_verbose,        default: false
    mattr_accessor :new_content_service_debug_verbose,                default: false
    mattr_accessor :report_task_job_debug_verbose,                    default: false

    mattr_accessor :attach_files_to_work_upload_files_asynchronously, default: false
    mattr_accessor :characterization_service_debug_verbose,           default: false
    mattr_accessor :ingest_allowed_path_prefixes,                     default: []
    mattr_accessor :ingest_append_ui_allowed_base_directories,        default: []
    mattr_accessor :ingest_append_ui_allow_scripts_to_run,            default: true

    mattr_accessor :ingest_script_tracking_dir_base,                  default: Rails.root.join('tmp', 'scripts')
    mattr_accessor :ingest_script_tracking_dir_expand_id,             default: true

    mattr_accessor :characterize_excluded_ext_set,                    default: {}
    mattr_accessor :characterize_enforced_mime_type,                  default: {}

    mattr_accessor :characterize_mime_type_ext_mismatch,              default: {}
    mattr_accessor :characterize_mime_type_ext_mismatch_fix,          default: {}

    mattr_accessor :ingest_append_queue_name,                         default: 'batch_update'

    mattr_accessor :ingest_script_dir
    mattr_accessor :deepbluedata_prep

  end

end
