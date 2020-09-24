
# monkey

module Hydra::Works
  module Derivatives

    HYDRA_WORKS_DERIVATIVES_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.hydra_works_derivatives_debug_verbose

    extend ActiveSupport::Concern
    include Hydra::Derivatives

    included do
      # Sets output_file_service to PersistDerivative instead of default Hydra::Derivatives::PersistBasicContainedOutputFileService
      Hydra::Derivatives.output_file_service = Hydra::Works::PersistDerivative
    end

    attr_reader :create_derivatives_duration

    # Note, these derivatives are being fetched from Fedora, so there may be more
    # network traffic than necessary.  If you want to avoid this, set up a
    # source_file_service that fetches the files locally, as is done in CurationConcerns.
    def create_derivatives
      started = DateTime.now
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "started=#{started}",
                                             "" ] if HYDRA_WORKS_DERIVATIVES_DEBUG_VERBOSE
      case original_file.mime_type
      when *self.class.pdf_mime_types
        Hydra::Derivatives::PdfDerivatives.create(self,
                                                  source: :original_file,
                                                  outputs: [{ label: :thumbnail,
                                                              format: 'jpg',
                                                              size: '338x493',
                                                              object: self }])
      when *self.class.office_document_mime_types
        Hydra::Derivatives::DocumentDerivatives.create(self,
                                                       source: :original_file,
                                                       outputs: [{ label: :thumbnail,
                                                                   format: 'jpg',
                                                                   size: '200x150>',
                                                                   object: self }])
      when *self.class.video_mime_types
        Hydra::Derivatives::VideoDerivatives.create(self,
                                                    source: :original_file,
                                                    outputs: [{ label: :thumbnail, format: 'jpg', object: self }])
      when *self.class.image_mime_types
        Hydra::Derivatives::ImageDerivatives.create(self,
                                                    source: :original_file,
                                                    outputs: [{ label: :thumbnail,
                                                                format: 'jpg',
                                                                size: '200x150>',
                                                                object: self }])
        ended_normally = DateTime.now
        create_derivatives_duration = ended_normally.to_i-started.to_i
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "started=#{started}",
                                               "ended_normally=#{ended_normally}",
                                               "create_derivatives_duration=#{ActiveSupport::Duration.build(create_derivatives_duration).inspect}",
                                               "" ] if HYDRA_WORKS_DERIVATIVES_DEBUG_VERBOSE
      end
    rescue Exception => e # rubocop:disable Lint/RescueException
      ended_abnormally = DateTime.now
      create_derivatives_duration = ended_abnormally.to_i-started.to_i
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "started=#{started}",
                                             "ended_abnormally=#{ended_normally}",
                                             "e.message=#{e.message}",
                                             "create_derivatives_duration=#{ActiveSupport::Duration.build(create_derivatives_duration).inspect}",
                                             "" ] if HYDRA_WORKS_DERIVATIVES_DEBUG_VERBOSE
      raise
    end
  end
end
