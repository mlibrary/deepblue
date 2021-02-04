# frozen_string_literal: true

module Deepblue

  module IngestIntegrationService

    @@_setup_ran = false
    @@_setup_failed = false

    @@abstract_ingest_job_debug_verbose = false
    @@add_file_to_file_set_debug_verbose = false
    @@attach_files_to_work_job_debug_verbose = false
    @@attach_files_to_work_upload_files_asynchronously = false
    @@characterize_job_debug_verbose = false
    @@characterization_service_verbose = false
    @@create_derivatives_job_debug_verbose = false
    @@ingest_allowed_path_prefixes = []
    @@ingest_append_ui_allowed_base_directories = []
    @@ingest_append_ui_allow_scripts_to_run = true
    @@ingest_content_service_debug_verbose = false
    @@ingest_helper_debug_verbose = false
    @@ingest_job_debug_verbose = false
    @@ingest_job_status_debug_verbose = false
    @@ingest_script_job_debug_verbose = false
    @@multiple_ingest_scripts_job_debug_verbose = false
    @@new_content_service_debug_verbose = false

    @@characterize_excluded_ext_set
    @@characterize_enforced_mime_type

    @@characterize_mime_type_ext_mismatch
    @@characterize_mime_type_ext_mismatch_fix

    @@ingest_append_queue_name = 'batch_update'
    @@ingest_script_dir

    @@deepbluedata_prep

    mattr_accessor :abstract_ingest_job_debug_verbose,
                   :add_file_to_file_set_debug_verbose,
                   :attach_files_to_work_job_debug_verbose,
                   :attach_files_to_work_upload_files_asynchronously,
                   :characterize_excluded_ext_set,
                   :characterize_enforced_mime_type,
                   :characterize_job_debug_verbose,
                   :characterize_mime_type_ext_mismatch,
                   :characterize_mime_type_ext_mismatch_fix,
                   :characterization_service_verbose,
                   :create_derivatives_job_debug_verbose,
                   :deepbluedata_prep,
                   :ingest_allowed_path_prefixes,
                   :ingest_append_ui_allowed_base_directories,
                   :ingest_append_ui_allow_scripts_to_run,
                   :ingest_append_queue_name,
                   :ingest_content_service_debug_verbose,
                   :ingest_helper_debug_verbose,
                   :ingest_job_debug_verbose,
                   :ingest_job_status_debug_verbose,
                   :ingest_script_dir,
                   :ingest_script_job_debug_verbose,
                   :multiple_ingest_scripts_job_debug_verbose,
                   :new_content_service_debug_verbose

    def self.setup
      return if @@_setup_ran == true
      @@_setup_ran = true
      begin
        yield self
      rescue Exception => e # rubocop:disable Lint/RescueException
        @@_setup_failed = true
      end
    end

  end

end
