# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/controllers/hyrax/dashboard/collections_controller.rb" )

module Hyrax

  module Dashboard

    # monkey patch Hyrax::Dashboard::CollectionsController

    ## Shows a list of all collections to the admins
    class CollectionsController < Hyrax::My::CollectionsController
      include ::Hyrax::BrandingHelper
      include Deepblue::CollectionsControllerBehavior

      # begin monkey
      mattr_accessor :collections_controller_debug_verbose,
                     default: ::DeepBlueDocs::Application.config.collections_controller_debug_verbose
      # end monkey

      EVENT_NOTE = 'Hyrax::Dashboard::CollectionsController'
      PARAMS_KEY = 'collection'

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
            unless ::DeepBlueDocs::Application.config.rest_api_allow_mutate
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

      def show
        respond_to do |wants|
          wants.html do
            show_rest
          end
          wants.json do
            unless ::DeepBlueDocs::Application.config.rest_api_allow_read
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

      ## end monkey patch overrides

      before_action :provenance_log_update_before, only: [:update]
      after_action :provenance_log_update_after, only: [:update]

      def curation_concern
        @collection ||= ::PersistHelper.find(params[:id])
      end

      def default_event_note
        EVENT_NOTE
      end

      def params_key
        PARAMS_KEY
      end

      ## begin monkey patch banner

      def process_banner_input
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@collection.id = #{@collection.id}",
        #                                        "" ] if collections_controller_debug_verbose
        return update_existing_banner if params["banner_unchanged"] == "true"
        remove_banner
        uploaded_file_ids = params["banner_files"]
        add_new_banner(uploaded_file_ids) if uploaded_file_ids
      end

      def update_existing_banner
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@collection.id = #{@collection.id}",
        #                                        "" ] if collections_controller_debug_verbose
        banner_info = collection_banner_info( id: @collection.id )
        banner_info.first.save(banner_info.first.local_path, false)
      end

      def add_new_banner(uploaded_file_ids)
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@collection.id = #{@collection.id}",
        #                                        "uploaded_file_ids = #{uploaded_file_ids}",
        #                                        "" ] if collections_controller_debug_verbose
        f = uploaded_files(uploaded_file_ids).first
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@collection.id = #{@collection.id}",
        #                                        "f.file_url = #{f.file_url}",
        #                                        "" ] if collections_controller_debug_verbose
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
        #                                        "" ] if collections_controller_debug_verbose
        banner_info = collection_banner_info( id: @collection.id )
        banner_info&.delete_all
      end

      ## end monkey patch banner

    end

  end

end
