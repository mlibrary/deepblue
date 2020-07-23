module Hyrax
  class SingleUseLinksController < ApplicationController

    SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.single_use_links_controller_debug_verbose

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
        redirect_to main_app.root_url, alert: "You do not have sufficient privileges to create links to this document"
      else
        session["user_return_to"] = request.url
        redirect_to new_user_session_url, alert: exception.message
      end
    end

    def create_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      @su = SingleUseLink.create itemId: params[:id], path: hyrax.download_path(id: params[:id])
      render plain: hyrax.download_single_use_link_url(@su.downloadKey)
    end

    def create_show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      @su = SingleUseLink.create(itemId: params[:id], path: asset_show_path)
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
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      links = SingleUseLink.where(itemId: params[:id]).map { |link| show_presenter.new(link) }
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "links=#{links}",
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      render partial: 'hyrax/file_sets/single_use_link_rows', locals: { single_use_links: links }
    end

    def destroy
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if SINGLE_USE_LINKS_CONTROLLER_DEBUG_VERBOSE
      SingleUseLink.find_by_downloadKey(params[:link_id]).destroy
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
