# frozen_string_literal: true

module Deepblue

  module SingleUseLinkControllerBehavior

    mattr_accessor :single_use_link_controller_behavior_debug_verbose,
                   default: ::Hyrax::SingleUseLinkService.single_use_link_controller_behavior_debug_verbose

    INVALID_SINGLE_USE_LINK = ''.freeze

    include ActionView::Helpers::TranslationHelper

    def render_single_use_error( exception )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if single_use_link_controller_behavior_debug_verbose
      if single_use_link_controller_behavior_debug_verbose
        logger.error( "Rendering PAGE due to exception: #{exception.inspect} - #{exception.backtrace[0..10] if exception.respond_to? :backtrace}" )
      end
      # render 'single_use_error', layout: "error", status: 404
      redirect_to main_app.root_path, alert: single_use_link_expired_msg
    end

    def single_use_link_destroy!( su_link )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "single_use_link_but_not_really=#{::Hyrax::SingleUseLinkService.single_use_link_but_not_really}",
                                             "" ] if single_use_link_controller_behavior_debug_verbose
      return if ::Hyrax::SingleUseLinkService.single_use_link_but_not_really
      return unless su_link.is_a? SingleUseLink
      rv = su_link.destroy!
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv = su_link.destroy!=#{rv}",
                                             "" ] if single_use_link_controller_behavior_debug_verbose
      return rv
    end

    def single_use_link_expired_msg
      t('hyrax.single_use_links.expired_html')
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
                                             "item_id=#{item_id}",
                                             "path=#{path}",
                                             "destroy_if_not_valid=#{destroy_if_not_valid}",
                                             "" ] if single_use_link_controller_behavior_debug_verbose
      return destroy_and_return_rv( destroy_flag: destroy_if_not_valid, rv: false, su_link: su_link ) unless su_link.valid?
      if item_id.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "item_id=#{item_id}",
                                               "su_link.itemId=#{su_link.itemId}",
                                               "destroy unless?=#{su_link.itemId == item_id}",
                                               "" ] if single_use_link_controller_behavior_debug_verbose
        return destroy_and_return_rv( destroy_flag: destroy_if_not_valid, rv: false, su_link: su_link ) unless su_link.itemId == item_id
      end
      if path.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "path=#{path}",
                                               "su_link.path=#{su_link.path}",
                                               "destroy unless?=#{su_link.path_eq? path}",
                                               "" ] if single_use_link_controller_behavior_debug_verbose
        return destroy_and_return_rv( destroy_flag: destroy_if_not_valid, rv: false, su_link: su_link ) unless su_link.path_eq? path
      end
      return true
    end

    private

      def destroy_and_return_rv( destroy_flag:, rv:, su_link: )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "destroy_flag=#{destroy_flag}",
                                               "" ] if single_use_link_controller_behavior_debug_verbose
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

  end

end
