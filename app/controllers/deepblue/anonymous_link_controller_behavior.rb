# frozen_string_literal: true

module Deepblue

  module AnonymousLinkControllerBehavior

    mattr_accessor :anonymous_link_controller_behavior_debug_verbose,
                   default: ::Hyrax::AnonymousLinkService.anonymous_link_controller_behavior_debug_verbose

    include ActionView::Helpers::TranslationHelper

    def anonymous_link_expired_msg
      t('hyrax.anonymous_links.expired_html')
    end

    def anonymous_link_obj( link_id: )
      @anonymous_link_obj ||= ::Hyrax::AnonymousLinkService.find_anonymous_link_obj( link_id: link_id )
    end

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

  end

end
