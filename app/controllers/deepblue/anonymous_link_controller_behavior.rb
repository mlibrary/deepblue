# frozen_string_literal: true

module Deepblue

  module AnonymousLinkControllerBehavior

    mattr_accessor :anonymous_link_controller_behavior_debug_verbose,
                   default: ::Hyrax::AnonymousLinkService.anonymous_link_controller_behavior_debug_verbose

    INVALID_ANONYMOUS_LINK = ''.freeze

    include ActionView::Helpers::TranslationHelper

    def render_anonymous_error( exception )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if anonymous_link_controller_behavior_debug_verbose
      if anonymous_link_controller_behavior_debug_verbose
        logger.error( "Rendering PAGE due to exception: #{exception.inspect} - #{exception.backtrace[0..10] if exception.respond_to? :backtrace}" )
      end
      # render 'anonymous_error', layout: "error", status: 404
      redirect_to main_app.root_path, alert: anonymous_link_expired_msg
    end

    # NOTE: only destroy anonymous links to published, tombstoned, deleted works
    def anonymous_link_destroy!( anon_link )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             # "::Hyrax::AnonymousLinkService.anonymous_link_but_not_really=#{::Hyrax::AnonymousLinkService.config.anonymous_link_but_not_really}",
                                             "" ] if anonymous_link_controller_behavior_debug_verbose
      # return if ::Hyrax::AnonymousLinkService.anonymous_link_but_not_really
      return unless anon_link.is_a? AnonymousLink
      rv = anon_link.destroy!
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv = anon_link.destroy!=#{rv}",
                                             "" ] if anonymous_link_controller_behavior_debug_verbose
      return rv
    end

    def anonymous_link_expired_msg
      t('hyrax.anonymous_links.expired_html')
    end

    def anonymous_link_obj( link_id: )
      @anonymous_link_obj ||= find_anonymous_link_obj( link_id: link_id )
    end

    def anonymous_link_valid?( anon_link, item_id: nil, path: nil, destroy_if_not_valid: false )
      return false unless anon_link.is_a? AnonymousLink
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link.valid?=#{anon_link.valid?}",
                                             "anon_link.itemId=#{anon_link.itemId}",
                                             "anon_link.path=#{anon_link.path}",
                                             "item_id=#{item_id}",
                                             "path=#{path}",
                                             "destroy_if_not_valid=#{destroy_if_not_valid}",
                                             "" ] if anonymous_link_controller_behavior_debug_verbose
      return destroy_if_necessary_and_return_rv( destroy_flag: destroy_if_not_valid,
                                    rv: false,
                                    anon_link: anon_link ) unless anon_link.valid?
      if item_id.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "item_id=#{item_id}",
                                               "anon_link.itemId=#{anon_link.itemId}",
                                               "destroy unless?=#{anon_link.itemId == item_id}",
                                               "" ] if anonymous_link_controller_behavior_debug_verbose
        return destroy_if_necessary_and_return_rv( destroy_flag: destroy_if_not_valid,
                                      rv: false,
                                      anon_link: anon_link ) unless anon_link.itemId == item_id
      end
      if path.present?
        anon_link_path = anon_link_strip_locale anon_link.path
        path = anon_link_strip_locale path
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "path=#{path}",
                                               "anon_link_path=#{anon_link_path}",
                                               "destroy unless?=#{anon_link_path == path}",
                                               "" ] if anonymous_link_controller_behavior_debug_verbose
        return destroy_if_necessary_and_return_rv( destroy_flag: destroy_if_not_valid,
                                      rv: false,
                                      anon_link: anon_link ) unless anon_link_path == path
      end
      return true
    end

    private

      def destroy_if_necessary_and_return_rv( destroy_flag:, rv:, anon_link: )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "destroy_flag=#{destroy_flag}",
                                               "" ] if anonymous_link_controller_behavior_debug_verbose
        return rv unless destroy_flag
        anonymous_link_destroy! anon_link
        return rv
      end

      def find_anonymous_link_obj( link_id: )
        return INVALID_ANONYMOUS_LINK if link_id.blank?
        rv = AnonymousLink.find_by_downloadKey!( link_id )
        return rv
      rescue ActiveRecord::RecordNotFound => _ignore
        return INVALID_ANONYMOUS_LINK # blank, so we only try looking it up once
      end

      def anon_link_strip_locale( path )
        if path =~ /^(.+)\?.+/
          return Regexp.last_match[1]
        end
        return path
      end

  end

end
