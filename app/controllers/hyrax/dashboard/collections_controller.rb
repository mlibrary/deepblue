# frozen_string_literal: true
# monkey
require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/controllers/hyrax/dashboard/collections_controller.rb" )

module Hyrax

  module Dashboard

    # monkey patch Hyrax::Dashboard::CollectionsController

    ## Shows a list of all collections to the admins
    class CollectionsController < ::Hyrax::My::CollectionsController
      include Blacklight::AccessControls::Catalog
      include Blacklight::Base

      configure_blacklight do |config|
        config.search_builder_class = Hyrax::Dashboard::CollectionsSearchBuilder
      end

      include ::Hyrax::BrandingHelper
      include ::Deepblue::CollectionsControllerBehavior

      # begin monkey
      include ::Deepblue::DoiControllerBehavior
      # end monkey

      # begin monkey
      mattr_accessor :dashboard_collections_controller_debug_verbose,
                     default: Rails.configuration.dashboard_collections_controller_debug_verbose
      # end monkey

      rescue_from ::ActiveFedora::ObjectNotFoundError, with: :unknown_id_rescue
      rescue_from ::Hyrax::ObjectNotFoundError, with: :unknown_id_rescue

      def unknown_id_rescue(e)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               "current_ability.admin?=#{current_ability.admin?}",
                                               "e=#{e.pretty_inspect}",
                                               "" ] if dashboard_collections_controller_debug_verbose
        url = if current_ability.admin?
                # attempt to pull id out of e.message:
                # ActiveFedora::ObjectNotFoundError: Couldn't find DataSet with 'id'=xyz
                if e.message =~ /^.*\=(.+)$/
                  id = Regexp.last_match(1)
                  "/data/provenance_log/#{id}"
                else
                  "/data/provenance_log/"
                end
              else
                main_app.root_path
              end
        redirect_to url, alert: "<br/>Unknown ID: #{e.message}<br/><br/>"
      end

      EVENT_NOTE = 'Hyrax::Dashboard::CollectionsController' unless const_defined? :EVENT_NOTE
      PARAMS_KEY = 'collection' unless const_defined? :PARAMS_KEY

      ## begin monkey patch overrides

      alias_method :monkey_after_create, :after_create
      alias_method :monkey_destroy, :destroy

      def after_create
        monkey_after_create
        workflow_create
      end

      def destroy
        respond_to do |wants|
          wants.html do
            destroy_rest
          end
          wants.json do
            unless Rails.configuration.rest_api_allow_mutate
              return render_json_response( response_type: :bad_request, message: "Method not allowed." )
            end
            destroy_rest
          end
        end
      end

      def destroy_rest
        workflow_destroy
        monkey_destroy
      end

      def doi_redirect_after( msg )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "override doi_redirect_after",
                                               "" ] if doi_controller_behavior_debug_verbose
        # redirect_to [main_app, curation_concern], notice: msg
        redirect_to url_for(action: 'show'), notice: msg
      end

      def show
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               Deepblue::LoggingHelper.obj_class( 'class', self ),
                                               "params[:id]=#{params[:id]}",
                                               "params=#{params}" ] if dashboard_collections_controller_debug_verbose
        respond_to do |wants|
          wants.html do
            show_rest
          end
          wants.json do
            unless Rails.configuration.rest_api_allow_read
              return render_json_response( response_type: :bad_request, message: "Method not allowed." )
            end
            show_rest
          end
        end
      end

      def show_rest
        if @collection.collection_type.brandable?
          banner_info = collection_banner_info( id: @collection.id )
          @banner = brand_path( collection_branding_info: banner_info.first ) unless banner_info.empty?
        end
        presenter
        query_collection_members
      end

      # This method was monkey patched becuase we wanted the users to go back to
      # the collection page, rather than stay in Edit collection page as hyrax does.
      def update
        unless params[:update_collection].nil?
          process_banner_input
          process_logo_input
        end

        process_member_changes
        @collection.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE unless @collection.discoverable?
        # we don't have to reindex the full graph when updating collection
        @collection.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
        if @collection.update(collection_params.except(:members))
          # This is the reason for the monkey patch.
          redirect_to hyrax.dashboard_collection_path, notice: t('hyrax.dashboard.my.action.collection_update_success')
        else
          after_update_error
        end
      end

      ## end monkey patch overrides

      before_action :provenance_log_update_before, only: [:update]
      after_action :provenance_log_update_after, only: [:update]

      def curation_concern
        # @collection ||= ::PersistHelper.find(params[:id]) # hyax v2 version
        # Query Solr for the collection.
        # run the solr query to find the collection members
        response, _docs = single_item_search_service.search_results
        curation_concern = response.documents.first
        raise CanCan::AccessDenied unless curation_concern
        curation_concern
      end

      def default_event_note
        EVENT_NOTE
      end

      def params_key
        PARAMS_KEY
      end

      def presenter
        @presenter ||= begin
                         presenter_class.new(curation_concern, current_ability)
                       end
      end

      ## begin monkey patch banner

      def process_banner_input
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@collection.id = #{@collection.id}",
        #                                        "" ] if dashboard_collections_controller_debug_verbose
        return update_existing_banner if params["banner_unchanged"] == "true"
        remove_banner
        uploaded_file_ids = params["banner_files"]
        add_new_banner(uploaded_file_ids) if uploaded_file_ids
      end

      def update_existing_banner
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@collection.id = #{@collection.id}",
        #                                        "" ] if dashboard_collections_controller_debug_verbose
        banner_info = collection_banner_info( id: @collection.id )
        # banner_info = CollectionBrandingInfo.where(collection_id: @collection.id.to_s).where(role: "banner")
        banner_info.first.save(banner_info.first.local_path, false)
      end

      def add_new_banner(uploaded_file_ids)
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@collection.id = #{@collection.id}",
        #                                        "uploaded_file_ids = #{uploaded_file_ids}",
        #                                        "" ] if dashboard_collections_controller_debug_verbose
        f = uploaded_files(uploaded_file_ids).first
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@collection.id = #{@collection.id}",
        #                                        "f.file_url = #{f.file_url}",
        #                                        "" ] if dashboard_collections_controller_debug_verbose
        banner_info = CollectionBrandingInfo.new(
            collection_id: @collection.id,
            filename: File.split(f.file_url).last,
            role: "banner",
            alt_txt: "",
            target_url: ""
        )
        banner_info.save f.file_url
      end

      def remove_banner
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@collection.id = #{@collection.id}",
        #                                        "" ] if dashboard_collections_controller_debug_verbose
        banner_info = collection_banner_info( id: @collection.id )
        # banner_info = CollectionBrandingInfo.where(collection_id: @collection.id.to_s).where(role: "banner")
        banner_info&.delete_all
      end

      def process_logo_records(uploaded_file_ids)
        public_files = []
        uploaded_file_ids.each_with_index do |ufi, i|
          # If user has chosen a new logo, the ufi will be an integer
          # If the logo was previously chosen, the ufil will be a path
          # ufi.match(/\D/) will return a nil, fi ufi is an integer
          # if it is a path, you want to update the, else create a new rec
          if ! ufi.match(/\D/).nil?
            update_logo_info(ufi, params["alttext"][i], verify_linkurl(params["linkurl"][i]))
            public_files << ufi
          else # brand new one, insert in the database
            logo_info = create_logo_info(ufi, params["alttext"][i], verify_linkurl(params["linkurl"][i]))
            public_files << logo_info.local_path
          end
        end
        public_files
      end

      ## end monkey patch banner

    end

  end

end
