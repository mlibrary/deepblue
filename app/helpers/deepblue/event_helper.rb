# frozen_string_literal: true

module Deepblue

  module EventHelper

    def self.after_batch_create_failure_callback( user: )
      LoggingCallback.process_event_user( event_name: :after_batch_create_failure, user: user )
    end

    def self.after_batch_create_success_callback( user: )
      LoggingCallback.process_event_user( event_name: :after_batch_create_success, user: user )
    end

    def self.after_create_concern_callback( curation_concern:, user: )
      LoggingCallback.process_event_curation_concern( event_name: :after_create_concern,
                                                      curation_concern: curation_concern,
                                                      user: user )
      curation_concern.provenance_create( current_user: user, event_note: 'after_create_concern' ) if curation_concern.respond_to? :provenance_create
    end

    def self.after_create_fileset_callback( file_set:, user: )
      LoggingCallback.process_event_file_set( event_name: :after_create_fileset, file_set: file_set, user: user )
      file_set.ingest_end( called_from: 'EventHelper.after_create_fileset_callback' ) if file_set.respond_to? :ingest_end
      file_set.provenance_create( current_user: user, event_note: 'after_create_fileset' ) if file_set.respond_to? :provenance_create
    end

    def self.after_destroy_callback( id:, user: )
      LoggingCallback.process_event_user( event_name: :after_destroy, user: user, msg: "id: #{id}" )
    end

    def self.after_fixity_check_failure_callback( file_set:, checksum_audit_log: )
      LoggingCallback.process_event( event_name: :after_fixity_check_failure,
                                     msg: "file_set: #{file_set} checksum_audit_log: #{checksum_audit_log}" )
    end

    def self.after_import_url_failure_callback( file_set:, user: )
      LoggingCallback.process_event_file_set( event_name: :after_import_url_failure, file_set: file_set, user: user )
    end

    def self.after_revert_content_callback( file_set:, user: )
      LoggingCallback.process_event_file_set( event_name: :after_revert_content, file_set: file_set, user: user )
    end

    # :after_update_content callback replaced by after_perform block in IngestJob
    def self.after_update_content
      # TODO
    end

    def self.after_update_metadata_callback( curation_concern:, user: )
      LoggingCallback.process_event_curation_concern( event_name: :after_update_metadata,
                                                      curation_concern: curation_concern,
                                                      user: user )
      # return unless curation_concern.respond_to? :provenance_log_update_after
      # curation_concern.provenance_log_update_after( current_user: user, event_note: 'after_update_metadata' )
    end

  end

end
