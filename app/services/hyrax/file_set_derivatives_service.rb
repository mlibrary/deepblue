# frozen_string_literal: true
# Reviewed: hyrax4

# monkey

module Hyrax
  # Responsible for creating and cleaning up the derivatives of a file_set
  class FileSetDerivativesService

    mattr_accessor :file_set_derivatives_service_debug_verbose,
                   default: Rails.configuration.file_set_derivatives_service_debug_verbose # monkey

    attr_reader :file_set
    delegate :uri, :mime_type, to: :file_set

    # @param file_set [Hyrax::FileSet] At least for this class, it must have #uri and #mime_type
    def initialize(file_set)
      @file_set = file_set
    end

    def uri
      # If given a FileMetadata object, use its parent ID.
      if file_set.respond_to?(:file_set_id)
        file_set.file_set_id.to_s
      else
        file_set.uri
      end
    end

    def cleanup_derivatives
      derivative_path_factory.derivatives_for_reference(file_set).each do |path|
        FileUtils.rm_f(path)
      end
    end

    def valid?
      supported_mime_types.include?(mime_type)
    end

    def create_derivatives(filename)
      # begin monkey
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "About to call create_derivatives(#{filename})",
                                             # "" ] + caller_locations(0,20) if file_set_derivatives_service_debug_verbose
                                             "" ] if file_set_derivatives_service_debug_verbose
      create_derivatives_monkey(filename)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "Returned from call create_derivatives(#{filename})",
                                             "" ] if file_set_derivatives_service_debug_verbose
    rescue Exception => e # rubocop:disable Lint/RescueException
      # TODO: remove this in favor of higher catch (or make it configurable)
      # Rails.logger.error "create_derivatives error #{filename} - #{e.class}: #{e.message}" + caller_locations(0,10).join("\n")
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "create_derivatives error #{filename} - #{e.class}: #{e.message}",
                                             # "" ] + caller_locations(0,20) if file_set_derivatives_service_debug_verbose
                                             "" ] if file_set_derivatives_service_debug_verbose
      raise
      # monkey end
    end

    def create_derivatives_monkey(filename)
      case mime_type
      when *file_set.class.pdf_mime_types             then create_pdf_derivatives(filename)
      when *file_set.class.office_document_mime_types then create_office_document_derivatives(filename)
      when *file_set.class.audio_mime_types           then create_audio_derivatives(filename)
      when *file_set.class.video_mime_types           then create_video_derivatives(filename)
      when *file_set.class.image_mime_types           then create_image_derivatives(filename)
      end
    end

    # The destination_name parameter has to match up with the file parameter
    # passed to the DownloadsController
    def derivative_url(destination_name)
      path = derivative_path_factory.derivative_path_for_reference(derivative_url_target, destination_name)
      URI("file://#{path}").to_s
    end

    private

    # If given a FileMetadata object pass the file_set_id for derivative URL
    # creation.
    def derivative_url_target
      if file_set.try(:file_set_id)
        file_set.file_set_id.to_s
      else
        file_set
      end
    end

    def supported_mime_types
      file_set.class.pdf_mime_types +
          file_set.class.office_document_mime_types +
          file_set.class.audio_mime_types +
          file_set.class.video_mime_types +
          file_set.class.image_mime_types
    end

    def create_pdf_derivatives(filename)
      Hydra::Derivatives::PdfDerivatives.create(filename,
                                                outputs: [{
                                                              label: :thumbnail,
                                                              format: 'jpg',
                                                              size: '338x493',
                                                              url: derivative_url('thumbnail'),
                                                              layer: 0
                                                          }])
      extract_full_text(filename, uri)
    end

    def create_office_document_derivatives(filename)
      Hydra::Derivatives::DocumentDerivatives.create(filename,
                                                     outputs: [{
                                                                   label: :thumbnail, format: 'jpg',
                                                                   size: '200x150>',
                                                                   url: derivative_url('thumbnail'),
                                                                   layer: 0
                                                               }])
      extract_full_text(filename, uri)
    end

    def create_audio_derivatives(filename)
      Hydra::Derivatives::AudioDerivatives.create(filename,
                                                  outputs: [{ label: 'mp3', format: 'mp3', url: derivative_url('mp3') },
                                                            { label: 'ogg', format: 'ogg', url: derivative_url('ogg') }])
    end

    def create_video_derivatives(filename)
      Hydra::Derivatives::VideoDerivatives.create(filename,
                                                  outputs: [{ label: :thumbnail, format: 'jpg', url: derivative_url('thumbnail') },
                                                            { label: 'webm', format: 'webm', url: derivative_url('webm') },
                                                            { label: 'mp4', format: 'mp4', url: derivative_url('mp4') }])
    end

    def create_image_derivatives(filename)
      # We're asking for layer 0, becauase otherwise pyramidal tiffs flatten all the layers together into the thumbnail
      Hydra::Derivatives::ImageDerivatives.create(filename,
                                                  outputs: [{ label: :thumbnail,
                                                              format: 'jpg',
                                                              size: '200x150>',
                                                              url: derivative_url('thumbnail'),
                                                              layer: 0 }])
    end

    def derivative_path_factory
      Hyrax::DerivativePath
    end

    # Calls the Hydra::Derivates::FulltextExtraction unless the extract_full_text
    # configuration option is set to false
    # @param [String] filename of the object to be used for full text extraction
    # @param [String] uri to the file set (deligated to file_set)
    def extract_full_text(filename, uri)
      return unless Hyrax.config.extract_full_text?
      Hydra::Derivatives::FullTextExtract.create(filename,
                                                 outputs: [{ url: uri, container: "extracted_text" }])
    end
  end
end
