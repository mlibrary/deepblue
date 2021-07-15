# frozen_string_literal: true

module Hyrax

  class AnonymousLinksViewerController < DownloadsController

    mattr_accessor :anonymous_links_viewer_controller_debug_verbose,
                   default: ::DeepBlueDocs::Application.config.anonymous_links_viewer_controller_debug_verbose

    include ActionView::Helpers::TranslationHelper
    include Blacklight::Base
    include Blacklight::AccessControls::Catalog
    include ActionDispatch::Routing::PolymorphicRoutes
    include Deepblue::AnonymousLinkControllerBehavior

    skip_before_action :authorize_download!, only: :show
    skip_before_action :verify_authenticity_token, only: :download

    rescue_from AnonymousError, with: :render_anonymous_error
    rescue_from CanCan::AccessDenied, with: :render_anonymous_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_anonymous_error
    class_attribute :presenter_class
    self.presenter_class = DsFileSetPresenter
    copy_blacklight_config_from(::CatalogController)

    def tombstoned?
      return false unless asset.respond_to? :parent
      return false unless asset.parent.respond_to? :tombstone
      asset.parent.tombstone.present?
    end

    def download
      path = anonymous_link.path
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anonymous_link=#{anonymous_link}",
                                             "anonymous_link.path=#{anonymous_link.path}",
                                             "anonymous_link.class.name=#{anonymous_link.class.name}",
                                             "" ] if anonymous_links_viewer_controller_debug_verbose
      raise not_found_exception unless anonymous_link_valid?( anonymous_link, destroy_if_not_valid: true )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anonymous_link=#{anonymous_link}",
                                             "anonymous_link.path=#{anonymous_link.path}",
                                             "asset.class.name=#{asset.class.name}",
                                             "asset&.id=#{asset&.id}",
                                             # "hyrax.download_path(id: asset)=#{hyrax.download_path(id: asset)}",
                                             "" ] if anonymous_links_viewer_controller_debug_verbose
      raise not_found_exception unless anonymous_link_valid?( anonymous_link,
                                                               item_id: asset&.id,
                                                               destroy_if_not_valid: true )
      if path =~ /concern\/file_sets/
        anonymous_link_destroy! anonymous_link
        raise not_found_exception if tombstoned?
        send_content
      elsif path =~ /downloads\//
        anonymous_link_destroy! anonymous_link
        raise not_found_exception if tombstoned?
        send_content
      else
        url = "#{path}/#{params[:id]}"
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "url=#{url}",
                                               "" ] if anonymous_links_viewer_controller_debug_verbose
        redirect_to url, notice: t('hyrax.anonymous_links.notice.download')
      end
    end

    def show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "anonymous_link.class.name=#{anonymous_link.class.name}",
                                             "" ] if anonymous_links_viewer_controller_debug_verbose
      raise not_found_exception unless anonymous_link_valid?( anonymous_link, destroy_if_not_valid: true )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "anonymous_link.itemId=#{anonymous_link.itemId}",
                                             "" ] if anonymous_links_viewer_controller_debug_verbose
      _, document_list = search_results( id: anonymous_link.itemId )
      solr_doc = document_list.first
      model = solr_doc['has_model_ssim'].first
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "model=#{model}",
                                             "" ] if anonymous_links_viewer_controller_debug_verbose
      if 'FileSet' == model
        # TODO: properly generate this route
        url = "#{::DeepBlueDocs::Application.config.relative_url_root}/concern/file_sets/#{solr_doc.id}/anonymous_link/#{params[:id]}"
        flash_msg =  t('hyrax.anonymous_links.notice.show_file_html')
        # flash_msg =  t('hyrax.anonymous_links.notice.show_file_with_help_link_html', help_link: "#{::DeepBlueDocs::Application.config.relative_url_root}/help" )
      else
        # TODO: properly generate this route
        url = "#{::DeepBlueDocs::Application.config.relative_url_root}/concern/data_sets/#{solr_doc.id}/anonymous_link/#{params[:id]}"
        flash_msg =  t('hyrax.anonymous_links.notice.show_work_html')
        # flash_msg =  t('hyrax.anonymous_links.notice.show_work_with_help_link_html', help_link: "#{::DeepBlueDocs::Application.config.relative_url_root}/help" )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ] if anonymous_links_viewer_controller_debug_verbose
      redirect_to url, notice: flash_msg
    end

    private

    def search_builder_class
      AnonymousLinkSearchBuilder
    end

    def content_options
      super.tap do |options|
        options[:disposition] = 'attachment' if action_name == 'download'
      end
    end

    # This is called in a before filter. It causes @asset to be set.
    def authorize_download!
      authorize! :read, asset
    end

    def anonymous_link
      @anonymous_link ||= anonymous_link_obj( link_id: params[:id] )
    end

    def not_found_exception
      AnonymousError.new( t('hyrax.anonymous_links.error.not_found') )
    end

    def asset
      @asset ||= if anonymous_link.is_a? AnonymousLink
                   ::PersistHelper.find(anonymous_link.itemId)
                 else
                   ''
                 end
    end

    def current_ability
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user=#{current_user}",
                                             "anonymous_link=#{anonymous_link}",
                                             "" ] if anonymous_links_viewer_controller_debug_verbose
      @current_ability ||= AnonymousLinksViewerController::Ability.new current_user, anonymous_link
    end

    def _prefixes
      # This allows us to use the attributes templates in hyrax/base, while prefering
      # our local paths. Thus we are unable to just override `self.local_prefixes`
      @_prefixes ||= super + ['hyrax/base']
    end

    class Ability
      include CanCan::Ability

      attr_reader :anonymous_link

      def initialize(user, anonymous_link)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "user=#{user}",
                                               "anonymous_link=#{anonymous_link}",
                                               "" ] if AnonymousLinksViewerController.anonymous_links_viewer_controller_debug_verbose
        @user = user || ::User.new
        return if anonymous_link.blank?

        @anonymous_link = anonymous_link
        can :read, [ActiveFedora::Base, ::SolrDocument] do |obj|
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "anonymous_link&.valid?=#{anonymous_link&.valid?}",
                                                 "anonymous_link&.itemId=#{anonymous_link&.itemId}",
                                                 "obj.id=#{obj.id}",
                                                 "" ] if AnonymousLinksViewerController.anonymous_links_viewer_controller_debug_verbose
          anonymous_link.valid? && anonymous_link.itemId == obj.id # && anonymous_link.destroy!
        end
      end

    end

  end

end
