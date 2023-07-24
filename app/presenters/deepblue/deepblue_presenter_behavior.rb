# frozen_string_literal: true

module Deepblue

  module DeepbluePresenterBehavior

    mattr_accessor :deep_blue_presenter_behavior_debug_verbose,
                   default: Rails.configuration.deep_blue_presenter_debug_verbose

    include Rails.application.routes.url_helpers
    include ActionDispatch::Routing::PolymorphicRoutes
    include Blacklight::CatalogHelperBehavior

    def default_url_options
      Rails.application.config.action_mailer.default_url_options
    end

    def download_path_link( main_app:, curation_concern: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "main_app.class.name=#{main_app.class.name}",
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "curation_concern&.id=#{curation_concern&.id}",
                                             "" ] if deep_blue_presenter_behavior_debug_verbose
      return curation_concern.download_path_link( main_app: main_app,
                                                  curation_concern: curation_concern ) if curation_concern.respond_to? :download_path_link
      # Rails.application.routes.url_helpers.url_for( only_path: true,
      #                                               action: 'show',
      #                                               controller: 'downloads',
      #                                               id: curation_concern.id )
      return "/data/downloads/#{curation_concern.id}" # TODO: fix
    end

    def member_thumbnail_image_options( member )
      {}
    end

    def member_thumbnail_url_options( member )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if deep_blue_presenter_behavior_debug_verbose
      suppress_link = !member.can_download_file?( no_link: true )
      { suppress_link: suppress_link }
    end

    def member_thumbnail_post_process( main_app:, member:, tag: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "member.class.name=#{member.class.name}",
                                             "member&.id=#{member&.id}",
                                             "tag.class.name=#{tag.class.name}",
                                             "tag=#{tag}",
                                             "" ] if deep_blue_presenter_behavior_debug_verbose
      return tag if tag.blank?
      return member.thumbnail_post_process( tag: tag, main_app: main_app ) if member.respond_to? :thumbnail_post_process
      rv = tag.to_s.dup
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv.class.name=#{rv.class.name}",
                                             "rv=#{rv}",
                                             "" ] if deep_blue_presenter_behavior_debug_verbose
      rv.gsub!( 'data-context-href', 'data-reference' )
      rv.gsub!( 'concern/file_sets', 'downloads' )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if deep_blue_presenter_behavior_debug_verbose
      return rv
    end

    # Copied from: ActionView::Helpers::TextHelper.truncate
    def truncate(text, options = {}, &block)
      if text
        length  = options.fetch(:length, 30)

        content = text.truncate(length, options)
        content = options[:escape] == false ? content.html_safe : ERB::Util.html_escape(content)
        content << capture(&block) if block_given? && text.length > length
        content
      end
    end

  end

end
