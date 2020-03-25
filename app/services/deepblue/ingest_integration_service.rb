# frozen_string_literal: true

module Deepblue

  module IngestIntegrationService

    @@_setup_ran = false

    @@characterization_service_verbose = false

    @@characterize_excluded_ext_set
    @@characterize_enforced_mime_type

    @@characterize_mime_type_ext_mismatch
    @@characterize_mime_type_ext_mismatch_fix

    @@ingest_append_queue_name = 'ingest'

    mattr_accessor :characterize_excluded_ext_set,
                   :characterize_enforced_mime_type,
                   :characterize_mime_type_ext_mismatch,
                   :characterize_mime_type_ext_mismatch_fix,
                   :characterization_service_verbose,
                   :ingest_append_ui_allowed_base_directories,
                   :ingest_append_queue_name

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

  end

end
