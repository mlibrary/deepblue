# frozen_string_literal: true

module Deepblue

  module IngestIntegrationService

    @@_setup_ran = false
    @@_setup_failed = false

    @@characterization_service_verbose = false

    @@characterize_excluded_ext_set
    @@characterize_enforced_mime_type

    @@characterize_mime_type_ext_mismatch
    @@characterize_mime_type_ext_mismatch_fix

    @@ingest_append_queue_name = 'batch_update'
    @@ingest_script_dir

    @@deepbluedata_prep

    mattr_accessor :characterize_excluded_ext_set,
                   :characterize_enforced_mime_type,
                   :characterize_mime_type_ext_mismatch,
                   :characterize_mime_type_ext_mismatch_fix,
                   :characterization_service_verbose,
                   :deepbluedata_prep,
                   :ingest_append_ui_allowed_base_directories,
                   :ingest_append_ui_allow_scripts_to_run,
                   :ingest_append_queue_name,
                   :ingest_script_dir

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
