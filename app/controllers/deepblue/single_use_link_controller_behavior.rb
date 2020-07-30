# frozen_string_literal: true

module Deepblue

  module SingleUseLinkControllerBehavior

    SINGLE_USE_LINK_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.single_use_link_controller_behavior_debug_verbose

    INVALID_SINGLE_USE_LINK = ''.freeze

    def render_single_use_error( exception )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if SINGLE_USE_LINK_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      if SINGLE_USE_LINK_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        logger.error( "Rendering PAGE due to exception: #{exception.inspect} - #{exception.backtrace[0..10] if exception.respond_to? :backtrace}" )
      end
      # render 'single_use_error', layout: "error", status: 404
      redirect_to main_app.root_path, alert: single_use_link_expired_msg
    end

    def single_use_link_destroy!( su_link )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "config.single_use_link_but_not_really=#{::DeepBlueDocs::Application.config.single_use_link_but_not_really}",
                                             "" ] if SINGLE_USE_LINK_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      return if ::DeepBlueDocs::Application.config.single_use_link_but_not_really
      return unless su_link.is_a? SingleUseLink
      rv = su_link.destroy!
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv = su_link.destroy!=#{rv}",
                                             "" ] if SINGLE_USE_LINK_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      return
    end

    def single_use_link_expired_msg
      # TODO: i18n for this msg
      "Single Use Link Expired or Not Found\nDeep Blue Data could not locate the single use link. This link either expired or had been used previously. We apologize for the inconvenience. You might be interested in using the help page for looking up solutions."
    end

    def single_use_link_obj( link_id: )
      @single_use_link_obj ||= find_single_use_link_obj( link_id: link_id )
    end

    def single_use_link_valid?( su_link, item_id: nil, path: nil, destroy_if_not_valid: false )
      return false unless su_link.is_a? SingleUseLink
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link.valid?=#{su_link.valid?}",
                                             "su_link.itemId=#{su_link.itemId}",
                                             "su_link.path=#{su_link.path}",
                                             "" ] if SINGLE_USE_LINK_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      return destroy_and_return_rv( destroy_flag: destroy_if_not_valid, rv: false, su_link: su_link ) unless su_link.valid?
      if item_id.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "item_id=#{item_id}",
                                               "su_link.itemId=#{su_link.itemId}",
                                               "" ] if SINGLE_USE_LINK_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        return destroy_and_return_rv( destroy_flag: destroy_if_not_valid, rv: false, su_link: su_link ) unless su_link.itemId == item_id
      end
      if path.present?
        su_link_path = su_link_strip_locale su_link.path
        path = su_link_strip_locale path
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "path=#{path}",
                                               "su_link_path=#{su_link_path}",
                                               "" ] if SINGLE_USE_LINK_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        return destroy_and_return_rv( destroy_flag: destroy_if_not_valid, rv: false, su_link: su_link ) unless su_link_path == path
      end
      return true
    end

    private

      def destroy_and_return_rv( destroy_flag:, rv:, su_link: )
        return rv unless destroy_flag
        single_use_link_destroy! su_link
        return rv
      end

      def find_single_use_link_obj( link_id: )
        return INVALID_SINGLE_USE_LINK if link_id.blank?
        rv = SingleUseLink.find_by_downloadKey!( link_id )
        return rv
      rescue ActiveRecord::RecordNotFound => _ignore
        return INVALID_SINGLE_USE_LINK # blank, so we only try looking it up once
      end

      def su_link_strip_locale( path )
        if path =~ /^(.+)\&.+/
          return Regexp.last_match[1]
        end
        return path
      end

  end

end
