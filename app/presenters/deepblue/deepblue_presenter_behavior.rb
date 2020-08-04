# frozen_string_literal: true

module Deepblue

  module DeepbluePresenterBehavior

    # TODO: change to deep_blue_presenter_behavior_debug_verbose
    DEEP_BLUE_PRESENTER_BEHAVIOR_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.deep_blue_presenter_debug_verbose

    include Rails.application.routes.url_helpers
    include ActionDispatch::Routing::PolymorphicRoutes

    def default_url_options
      Rails.application.config.action_mailer.default_url_options
    end

    def download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "curation_concern&.id=#{curation_concern&.id}",
                                             "" ] if DEEP_BLUE_PRESENTER_BEHAVIOR_DEBUG_VERBOSE
      # Rails.application.routes.url_helpers.url_for( only_path: true,
      #                                               action: 'show',
      #                                               controller: 'downloads',
      #                                               id: curation_concern.id )
      return "/data/download/#{curation_concern.id}" # TODO: fix
    end

  end

end
