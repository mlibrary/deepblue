# frozen_string_literal: true

module Hyrax

  class AnonymousLinksController < ApplicationController

    mattr_accessor :anonymous_links_controller_debug_verbose,
                   default: ::Hyrax::AnonymousLinkService.anonymous_links_controller_debug_verbose

    include ActionView::Helpers::TranslationHelper
    include Blacklight::SearchHelper
    class_attribute :show_presenter
    self.show_presenter = Hyrax::AnonymousLinkPresenter
    before_action :authenticate_user!
    before_action :authorize_user!
    # Catch permission errors
    rescue_from Hydra::AccessDenied, CanCan::AccessDenied, with: :deny_link_access

    def deny_link_access(exception)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if anonymous_links_controller_debug_verbose
      if current_user&.persisted?
        redirect_to main_app.root_url, alert:  t('hyrax.anonymous_links.alert.insufficient_privileges')
      else
        session["user_return_to"] = request.url
        redirect_to new_user_session_url, alert: exception.message
      end
    end

    def create_anonymous_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_type]=#{params[:link_type]}",
                                             "params=#{params}",
                                             "" ] if anonymous_links_controller_debug_verbose
      asset_path = asset_show_path
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "asset_path=#{asset_path}",
                                             "" ] if anonymous_links_controller_debug_verbose
      if asset_path =~ /concern\/file_sets/
        @anon = AnonymousLink.create( item_id: params[:id], path: hyrax.download_path(id: params[:id]) )
      else
        asset_path = asset_path.gsub( /\?locale\=.+$/, '/anonymous_link_zip_download' )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "asset_path=#{asset_path}",
                                               "" ] if anonymous_links_controller_debug_verbose
        @anon = AnonymousLink.create( item_id: params[:id], path: asset_path )
      end
      render plain: main_app.download_anonymous_link_url(@anon.download_key)
    end

    def create_anonymous_show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params=#{params}",
                                             "" ] if anonymous_links_controller_debug_verbose
      @anon = AnonymousLink.create( item_id: params[:id], path: asset_show_path )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@anon=#{@anon}",
                                             "" ] if anonymous_links_controller_debug_verbose
      url = main_app.show_anonymous_link_url(@anon.download_key)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ] if anonymous_links_controller_debug_verbose
      render plain: url
    end

    def index
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_type]=#{params[:link_type]}",
                                             "" ] if anonymous_links_controller_debug_verbose
      links = AnonymousLink.where( item_id: params[:id] ).map do |link|
        show_presenter.new( link )
      end
      pres = links.first
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "links=#{links}",
                                             "pres=#{pres}",
                                             "pres&.link=#{pres&.link}",
                                             "pres&.link_type=#{pres&.link_type}",
                                             "" ] if anonymous_links_controller_debug_verbose
      anon_link = pres&.link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link&.path=#{anon_link&.path}",
                                             "" ] if anonymous_links_controller_debug_verbose
      if anon_link =~ /concern\/file_sets/
        partial_path = 'hyrax/file_sets/anonymous_link_rows'
      else
        partial_path = 'hyrax/base/anonymous_link_rows'
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "partial_path=#{partial_path}",
                                             "" ] if anonymous_links_controller_debug_verbose
      render partial: partial_path, locals: { anonymous_links: links }
    end

    def destroy
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:anon_link_id]=#{params[:anon_link_id]}",
                                             "" ] if anonymous_links_controller_debug_verbose
      anon_link = AnonymousLink.find_by_download_key(params[:anon_link_id])
      anon_link.destroy if anon_link.present?
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
