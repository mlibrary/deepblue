# frozen_string_literal: true

module Hyrax

  class DeepbluePresenter < Hyrax::WorkShowPresenter

    include Deepblue::DeepbluePresenterBehavior

    # include Rails.application.routes.url_helpers
    # include ActionDispatch::Routing::PolymorphicRoutes

    DEEP_BLUE_PRESENTER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.deep_blue_presenter_debug_verbose

    def box_enabled?
      false
    end

    def can_download_using_globus_maybe?
      false
    end

    def can_display_provenance_log?
      false
    end

    def display_provenance_log_enabled?
      false
    end

    def doi_minting_enabled?
      false
    end

    def globus_download_enabled?
      false
    end

    def human_readable_type
      "Work"
    end

    def member_presenter_factory
      MemberPresenterFactory.new( solr_document, current_ability, request )
    end

    def zip_download_enabled?
      false
    end

  end

end
