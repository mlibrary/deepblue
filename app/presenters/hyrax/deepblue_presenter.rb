# frozen_string_literal: true

module Hyrax

  class DeepbluePresenter < Hyrax::WorkShowPresenter

    include ActionDispatch::Routing::PolymorphicRoutes

    DEEP_BLUE_PRESENTER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.deep_blue_presenter_debug_verbose

    def box_enabled?
      false
    end

    def display_provenance_log_enabled?
      false
    end

    def doi_minting_enabled?
      false
    end

    def download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "curation_concern&.id=#{curation_concern&.id}",
                                             "" ] if DEEP_BLUE_PRESENTER_DEBUG_VERBOSE
      "/data/download/#{curation_concern.id}" # TODO: fix
    end

    def globus_download_enabled?
      false
    end

    def human_readable_type
      "Work"
    end

    # def mint_doi_enabled?
    #   false
    # end

    # def tombstone_enabled?
    #   false
    # end

    def zip_download_enabled?
      false
    end

    def member_presenter_factory
      MemberPresenterFactory.new(solr_document, current_ability, request)
    end

  end

end
