# frozen_string_literal: true

module Hyrax

  class SingleUseLinksController < ApplicationController

    SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.single_use_links_controller_debug_verbose

    include ActionView::Helpers::TranslationHelper
    include Blacklight::SearchHelper
    class_attribute :show_presenter
    self.show_presenter = Hyrax::SingleUseLinkPresenter
    before_action :authenticate_user!
    before_action :authorize_user!
    # Catch permission errors
    rescue_from Hydra::AccessDenied, CanCan::AccessDenied, with: :deny_link_access

    def deny_link_access(exception)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      if current_user&.persisted?
        redirect_to main_app.root_url, alert:  t('hyrax.single_use_links.alert.insufficient_privileges')
      else
        session["user_return_to"] = request.url
        redirect_to new_user_session_url, alert: exception.message
      end
    end

    def create_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_type]=#{params[:link_type]}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      asset_path = asset_show_path
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "asset_path=#{asset_path}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      if asset_path =~ /concern\/file_sets/
        @su = SingleUseLink.create( itemId: params[:id],
                                    path: hyrax.download_path(id: params[:id]),
                                    user_id: current_ability.current_user.id )
      else
        asset_path = asset_path.gsub( /\?locale\=.+$/, '/single_use_link_zip_download' )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "asset_path=#{asset_path}",
                                               "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
        @su = SingleUseLink.create( itemId: params[:id],
                                    path: asset_path,
                                    user_id: current_ability.current_user.id )
      end
      render plain: hyrax.download_single_use_link_url(@su.downloadKey)
    end

    def create_show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      @su = SingleUseLink.create( itemId: params[:id],
                                  path: asset_show_path,
                                  user_id: current_ability.current_user.id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@su=#{@su}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      url = hyrax.show_single_use_link_url(@su.downloadKey)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      render plain: url
    end

    def index
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_type]=#{params[:link_type]}",
                                             "current_ability.current_user.id=#{current_ability.current_user.id}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      links = SingleUseLink.where( itemId: params[:id], user_id: current_ability.current_user.id ).map do |link|
        show_presenter.new( link )
      end
      pres = links.first
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "links=#{links}",
                                             "pres=#{pres}",
                                             "pres.link=#{pres.link}",
                                             "pres.link_type=#{pres.link_type}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      su_link = pres.link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link.path=#{su_link.path}",
                                             "su_link.user_id=#{su_link.user_id}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      if su_link =~ /concern\/file_sets/
        partial_path = 'hyrax/file_sets/single_use_link_rows'
      else
        partial_path = 'hyrax/base/single_use_link_rows'
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "partial_path=#{partial_path}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      render partial: partial_path, locals: { single_use_links: links }
    end

    def destroy
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:link_id]=#{params[:link_id]}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      su_link = SingleUseLink.find_by_downloadKey(params[:link_id])
      su_link.destroy if su_link.present?
      head :ok
    end

    private

      def authorize_user!
        authorize! :edit, params[:id]
      end

      def asset_show_path
        polymorphic_path([main_app, fetch(params[:id]).last])
      end

  end

end
