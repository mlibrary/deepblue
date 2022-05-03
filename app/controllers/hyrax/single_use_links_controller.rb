# frozen_string_literal: true

module Hyrax

  class SingleUseLinksController < ApplicationController

    mattr_accessor :single_use_links_controller_debug_verbose,
                   default: ::Hyrax::SingleUseLinkService.single_use_links_controller_debug_verbose

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
                                             "" ] if single_use_links_controller_debug_verbose
      if current_user&.persisted?
        redirect_to main_app.root_url, alert: t('hyrax.single_use_links.alert.insufficient_privileges')
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
                                             "params=#{params}",
                                             "" ] if single_use_links_controller_debug_verbose
      asset_path = asset_show_path
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "asset_path=#{asset_path}",
                                             "" ] if single_use_links_controller_debug_verbose
      if asset_path =~ /concern\/file_sets/
        @su = SingleUseLink.create( item_id: params[:id],
                                    path: hyrax.download_path(id: params[:id]),
                                    user_id: current_ability.current_user.id,
                                    user_comment: params[:user_comment] )
      else
        asset_path = asset_path.gsub( /\?locale\=.+$/, '/single_use_link_zip_download' )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "asset_path=#{asset_path}",
                                               "" ] if single_use_links_controller_debug_verbose
        @su = SingleUseLink.create( item_id: params[:id],
                                    path: asset_path,
                                    user_id: current_ability.current_user.id,
                                    user_comment: params[:user_comment] )
      end
      render plain: hyrax.download_single_use_link_url(@su.download_key)
    end

    def create_show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params=#{params}",
                                             "" ] if single_use_links_controller_debug_verbose
      @su = SingleUseLink.create( item_id: params[:id],
                                  path: asset_show_path,
                                  user_id: current_ability.current_user.id,
                                  user_comment: params[:user_comment] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@su=#{@su}",
                                             "" ] if single_use_links_controller_debug_verbose
      url = hyrax.show_single_use_link_url(@su.download_key)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ] if single_use_links_controller_debug_verbose
      render plain: url
    end

    def index
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_type]=#{params[:link_type]}",
                                             "current_ability.current_user.id=#{current_ability.current_user.id}",
                                             "" ] if single_use_links_controller_debug_verbose
      links = SingleUseLink.where( item_id: params[:id], user_id: current_ability.current_user.id ).map do |link|
        show_presenter.new( link )
      end
      pres = links.first
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "links=#{links}",
                                             "pres=#{pres}",
                                             "pres&.link=#{pres&.link}",
                                             "pres&.link_type=#{pres&.link_type}",
                                             "" ] if single_use_links_controller_debug_verbose
      su_link = pres&.link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link&.path=#{su_link&.path}",
                                             "su_link&.user_id=#{su_link&.user_id}",
                                             "" ] if single_use_links_controller_debug_verbose
      if su_link =~ /concern\/file_sets/
        partial_path = 'hyrax/file_sets/single_use_link_rows'
      else
        partial_path = 'hyrax/base/single_use_link_rows'
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "partial_path=#{partial_path}",
                                             "" ] if single_use_links_controller_debug_verbose
      render partial: partial_path, locals: { single_use_links: links }
    end

    def destroy
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:link_id]=#{params[:link_id]}",
                                             "" ] if single_use_links_controller_debug_verbose
      su_link = SingleUseLink.find_by_download_key(params[:link_id])
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
