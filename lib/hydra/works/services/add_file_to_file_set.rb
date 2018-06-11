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
      file_set.provenance_ingest( current_user: ProvenanceHelper.system_as_current_user, ingester: ProvenanceHelper.system_as_current_user )
      Rails.logger.debug ">>>>>>>>>>>>>"
      Rails.logger.debug "File attached to file set #{file_set.id}"
      Rails.logger.debug ">>>>>>>>>>>>>"
    end

  end
end
