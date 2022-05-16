# frozen_string_literal: true

module Hyrax

  class DeepbluePresenter < Hyrax::WorkShowPresenter

    include Deepblue::DeepbluePresenterBehavior

    # include Rails.application.routes.url_helpers
    # include ActionDispatch::Routing::PolymorphicRoutes

    DEEP_BLUE_PRESENTER_DEBUG_VERBOSE = Rails.configuration.deep_blue_presenter_debug_verbose

    def box_enabled?
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

    def tombstone_permissions_hack?
      false
    end

  end

end
