# frozen_string_literal: true

module Deepblue

  module DeepbluePresenterBehavior

    DEEP_BLUE_PRESENTER_BEHAVIOR_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.deep_blue_presenter_debug_verbose

    include Rails.application.routes.url_helpers
    include ActionDispatch::Routing::PolymorphicRoutes
    include Blacklight::CatalogHelperBehavior

    def default_url_options
      Rails.application.config.action_mailer.default_url_options
    end

    def download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "curation_concern&.id=#{curation_concern&.id}",
                                             "" ] if DEEP_BLUE_PRESENTER_BEHAVIOR_DEBUG_VERBOSE
      return curation_concern.download_path_link( curation_concern ) if curation_concern.respond_to? :download_path_link
      # Rails.application.routes.url_helpers.url_for( only_path: true,
      #                                               action: 'show',
      #                                               controller: 'downloads',
      #                                               id: curation_concern.id )
      return "/data/download/#{curation_concern.id}" # TODO: fix
    end

    def member_thumbnail_image_options( member )
      {}
    end

    def member_thumbnail_url_options( member )
      { suppress_link: member.can_download_file? }
    end

    def member_thumbnail_post_process( member, tag )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "member.class.name=#{member.class.name}",
                                             "member&.id=#{member&.id}",
                                             "tag.class.name=#{tag.class.name}",
                                             "tag=#{tag}",
                                             "" ] if DEEP_BLUE_PRESENTER_BEHAVIOR_DEBUG_VERBOSE
      return tag if tag.blank?
      rv = tag.to_s.dup
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv.class.name=#{rv.class.name}",
                                             "rv=#{rv}",
                                             "" ] if DEEP_BLUE_PRESENTER_BEHAVIOR_DEBUG_VERBOSE
      rv.gsub!( 'data-context-href', 'data-reference' )
      rv.gsub!( 'concern/file_sets', 'downloads' )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if DEEP_BLUE_PRESENTER_BEHAVIOR_DEBUG_VERBOSE
      return rv
    end

  end

end
