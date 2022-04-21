# frozen_string_literal: true

module Hydra::Works

  class UploadFileToFileSet

    mattr_accessor :upload_file_to_file_set_debug_verbose, default: false

    # Sets a file as the primary file (original_file) of the file_set
    # @param [Hydra::PCDM::FileSet] file_set the file will be added to
    # @param [IO,File,Rack::Multipart::UploadedFile, #read] object that will be the contents. If file responds to :mime_type or :original_name, those will be called to provide technical metadata.
    # @param [Array] additional_services (ie Generating Thumbnails) to call with file_set after adding the file as its original_file
    # @param [Boolean] update_existing whether to update an existing file if there is one. When set to true, performs a create_or_update. When set to false, always creates a new file within file_set.files.
    # @param [Boolean] versioning whether to create new version entries (only applicable if +type+ corresponds to a versionable file)

    def self.call(file_set, file, additional_services: [], update_existing: true, versioning: true)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if upload_file_to_file_set_debug_verbose

      Hydra::Works::AddFileToFileSet.call_enhanced_version(file_set,
                                                           file,
                                                           :original_file,
                                                           update_existing: update_existing,
                                                           versioning: versioning)

      # Call any additional services
      additional_services.each do |service|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               ::Deepblue::LoggingHelper.obj_class( "service", service ),
                                               "" ] if upload_file_to_file_set_debug_verbose
        service.call(file_set)
      end

      file_set.checksum_update_from_files if file_set.respond_to? :checksum_update_from_files
      file_set.save
      file_set
    end

  end

end
