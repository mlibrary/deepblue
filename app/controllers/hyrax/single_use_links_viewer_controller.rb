# frozen_string_literal: true
#  Reviewed: hyrax4

module Hyrax

  class SingleUseLinksViewerController < DownloadsController

    mattr_accessor :single_use_links_viewer_controller_debug_verbose,
                   default: ::Hyrax::SingleUseLinkService.single_use_links_viewer_controller_debug_verbose

    include ActionView::Helpers::TranslationHelper
    include Blacklight::Base
    include Blacklight::AccessControls::Catalog
    include ActionDispatch::Routing::PolymorphicRoutes
    include Deepblue::SingleUseLinkControllerBehavior

    skip_before_action :authorize_download!, only: :show
    skip_before_action :verify_authenticity_token, only: :download

    rescue_from SingleUseError, with: :render_single_use_error
    rescue_from CanCan::AccessDenied, with: :render_single_use_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_single_use_error
    class_attribute :presenter_class
    self.presenter_class = DsFileSetPresenter
    copy_blacklight_config_from(::CatalogController)

    def tombstoned?
      return false unless asset.respond_to? :parent
      return false unless asset.parent.respond_to? :tombstone
      asset.parent.tombstone.present?
    end

    configure_blacklight do |config|
      config.search_builder_class = SingleUseLinkSearchBuilder
    end

    def download
      path = single_use_link.path
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "single_use_link=#{single_use_link}",
                                             "single_use_link.path=#{single_use_link.path}",
                                             "single_use_link.class.name=#{single_use_link.class.name}",
                                             "" ] if single_use_links_viewer_controller_debug_verbose
      raise not_found_exception unless single_use_link_valid?( single_use_link, destroy_if_not_valid: true )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "single_use_link=#{single_use_link}",
                                             "single_use_link.path=#{single_use_link.path}",
                                             "asset.class.name=#{asset.class.name}",
                                             "asset&.id=#{asset&.id}",
                                             # "hyrax.download_path(id: asset)=#{hyrax.download_path(id: asset)}",
                                             "" ] if single_use_links_viewer_controller_debug_verbose
      raise not_found_exception unless single_use_link_valid?( single_use_link,
                                                               item_id: asset&.id,
                                                               destroy_if_not_valid: true )
      if path =~ /concern\/file_sets/
        single_use_link_destroy! single_use_link
        raise not_found_exception if tombstoned?
        send_content
      elsif path =~ /downloads\//
        single_use_link_destroy! single_use_link
        raise not_found_exception if tombstoned?
        send_content
      else
        url = "#{path}/#{params[:id]}"
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "url=#{url}",
                                               "" ] if single_use_links_viewer_controller_debug_verbose
        redirect_to url, notice: t('hyrax.single_use_links.notice.download')
      end
    end

    def show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "single_use_link.class.name=#{single_use_link.class.name}",
                                             "" ] if single_use_links_viewer_controller_debug_verbose
      raise not_found_exception unless single_use_link_valid?( single_use_link, destroy_if_not_valid: true )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "single_use_link.item_id=#{single_use_link.item_id}",
                                             "" ] if single_use_links_viewer_controller_debug_verbose
      # puts;puts "search_service.class.name=#{search_service.class.name}";puts
      _, document_list = search_results( id: single_use_link.item_id )
      solr_doc = document_list.first
      model = solr_doc['has_model_ssim'].first
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "model=#{model}",
                                             "" ] if single_use_links_viewer_controller_debug_verbose
      if 'FileSet' == model
        # TODO: properly generate this route
        url = "#{Rails.configuration.relative_url_root}/concern/file_sets/#{solr_doc.id}/single_use_link/#{params[:id]}"
        flash_msg =  t('hyrax.single_use_links.notice.show_file_html')
        # flash_msg =  t('hyrax.single_use_links.notice.show_file_with_help_link_html', help_link: "#{Rails.configuration.relative_url_root}/help" )
      else
        # TODO: properly generate this route
        url = "#{Rails.configuration.relative_url_root}/concern/data_sets/#{solr_doc.id}/single_use_link/#{params[:id]}"
        flash_msg =  t('hyrax.single_use_links.notice.show_work_html')
        # flash_msg =  t('hyrax.single_use_links.notice.show_work_with_help_link_html', help_link: "#{Rails.configuration.relative_url_root}/help" )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ] if single_use_links_viewer_controller_debug_verbose
      redirect_to url, notice: flash_msg
    end

    private

    def curation_concern
      response, _document_list = search_service.search_results
      response.documents.first
    end

    def search_service(*args)
      # puts "args=#{args}"
      # puts "blacklight_config.present?=#{blacklight_config.present?}"
      # puts "single_use_link.item_id=#{single_use_link.item_id}"
      rv = Hyrax::SearchService.new(config: blacklight_config, user_params: { id: single_use_link.item_id }, scope: self)
      # puts "rv=#{rv}"
      return rv
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

    def single_use_link
      @single_use_link ||= single_use_link_obj( link_id: params[:id] )
    end

    def not_found_exception
      SingleUseError.new( t('hyrax.single_use_links.error.not_found') )
    end

    def asset
      @asset ||= if single_use_link.is_a? SingleUseLink
                   ::PersistHelper.find(single_use_link.item_id)
                 else
                   ''
                 end
    end

    def current_ability
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user=#{current_user}",
                                             "single_use_link=#{single_use_link}",
                                             "" ] if single_use_links_viewer_controller_debug_verbose
      @current_ability ||= SingleUseLinksViewerController::Ability.new( current_user,
                                                                        single_use_link,
                                                                        single_use_links_viewer_controller_debug_verbose )
    end

    def _prefixes
      # This allows us to use the attributes templates in hyrax/base, while prefering
      # our local paths. Thus we are unable to just override `self.local_prefixes`
      @_prefixes ||= super + ['hyrax/base']
    end

    class Ability
      include CanCan::Ability

      attr_reader :single_use_link

      def initialize(user, single_use_link, debug_verbose = false)
        @debug_verbose = debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "user=#{user}",
                                               "single_use_link=#{single_use_link}",
                                               "" ] if debug_verbose
        @user = user || ::User.new
        return if single_use_link.blank?

        @single_use_link = single_use_link
        can :read, [ActiveFedora::Base, ::SolrDocument] do |obj|
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "single_use_link&.valid?=#{single_use_link&.valid?}",
                                                 "single_use_link&.item_id=#{single_use_link&.item_id}",
                                                 "obj.id=#{obj.id}",
                                                 "" ] if @debug_verbose
          single_use_link.valid? && single_use_link.item_id == obj.id # && single_use_link.destroy!
        end
      end

    end

  end

end
