# frozen_string_literal: true

require File.join(Gem::Specification.find_by_name("hydra-works").full_gem_path, "lib/hydra/works/services/add_file_to_file_set.rb")

module Hydra::Works

  # monkey patch Hyrdra::Works::AddFileToFileSet
  class AddFileToFileSet

    class << self
      alias_method :monkey_call, :call
    end

    # @param [Hydra::PCDM::FileSet] file_set the file will be added to
    # @param [IO,File,Rack::Multipart::UploadedFile, #read] file the object that will be the contents. If file responds to :mime_type, :content_type, :original_name, or :original_filename, those will be called to provide metadata.
    # @param [RDF::URI or String] type URI for the RDF.type that identifies the file's role within the file_set
    # @param [Boolean] update_existing whether to update an existing file if there is one. When set to true, performs a create_or_update. When set to false, always creates a new file within file_set.files.
    # @param [Boolean] versioning whether to create new version entries (only applicable if +type+ corresponds to a versionable file)
    def self.call( file_set, file, type, update_existing: true, versioning: true )
      monkey_call( file_set, file, type, update_existing: update_existing, versioning: versioning )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file=#{file}",
                                             ::Deepblue::LoggingHelper.obj_class( "file", file ) ]
      if file.respond_to? :user_id
        ingester = User.find file.user_id
        ingester = ingester.user_key
      elsif file.respond_to? :current_user
        ingester = file.current_user
      else
        ingester = Deepblue::ProvenanceHelper.system_as_current_user if ingester.nil?
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ingester=#{ingester}" ]
      file_set.provenance_ingest( current_user: Deepblue::ProvenanceHelper.system_as_current_user,
                                  calling_class: 'Hydra::Works::AddFileToFileSet',
                                  ingest_id: '',
                                  ingester: ingester,
                                  ingest_timestamp: nil )
      begin
        file_set.virus_scan
      rescue Exception => e # rubocop:disable Lint/RescueException
        Rails.logger.error "AddFileToFileSet #{file_set} #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end
      ::Deepblue::LoggingHelper.bold_debug "File attached to file set #{file_set.id}"
    end

  end

end
