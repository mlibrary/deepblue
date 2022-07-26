# frozen_string_literal: true

module Hyrax

  module My

    class CollectionsController < MyController

      mattr_accessor :hyrax_my_collections_controller_debug_verbose, default: false

      EVENT_NOTE = 'Hyrax::My::CollectionsController' unless const_defined? :EVENT_NOTE
      PARAMS_KEY = 'collection' unless const_defined? :PARAMS_KEY

      configure_blacklight do |config|
        config.search_builder_class = Hyrax::My::CollectionsSearchBuilder
      end

      # Define collection specific filter facets.
      def self.configure_facets
        configure_blacklight do |config|
          # Name of pivot facet must match field name that uses helper_method
          config.add_facet_field Hyrax.config.collection_type_index_field,
                                 helper_method: :collection_type_label, limit: 5,
                                 pivot: ['has_model_ssim', Hyrax.config.collection_type_index_field],
                                 label: I18n.t('hyrax.dashboard.my.heading.collection_type')
          # This causes AdminSets to also be shown with the Collection Type label
          config.add_facet_field 'has_model_ssim',
                                 label: I18n.t('hyrax.dashboard.my.heading.collection_type'),
                                 limit: 5, show: false
        end
      end
      configure_facets


      before_action :my_collections_controller_debug_output

      before_action :provenance_log_update_before, only: [:update]
      before_action :visiblity_changed,            only: [:update]

      after_action :provenance_log_update_after,   only: [:update]
      after_action :visibility_changed_update,     only: [:update]

      protect_from_forgery with: :null_session,    only: [:display_provenance_log]

      def my_collections_controller_debug_output
        # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                        Deepblue::LoggingHelper.called_from,
        #                                        "params=#{params}" ] if hyrax_my_collections_controller_debug_verbose
      end

      def curation_concern
        @collection ||= ::PersistHelper.find( params[:id] )
      end

      ## Provenance log

      def provenance_log_update_after
        # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                        Deepblue::LoggingHelper.called_from,
        #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
        #                                        "@update_attr_key_values=#{@update_attr_key_values}",
        #                                        "" ] if hyrax_my_collections_controller_debug_verbose
        curation_concern.provenance_log_update_after( current_user: current_user,
                                                      # event_note: 'CollectionsController.provenance_log_update_after',
                                                      update_attr_key_values: @update_attr_key_values )
      end

      def provenance_log_update_before
        # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                        Deepblue::LoggingHelper.called_from,
        #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
        #                                        "" ] if hyrax_my_collections_controller_debug_verbose
        return unless @update_attr_key_values.nil?
        @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
      end

      ## end Provenance log

      ## display provenance log

      def display_provenance_log
        # load provenance log for this work
        id = @collection.id # curation_concern.id
        file_path = Deepblue::ProvenancePath.path_for_reference( id )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "file_path=#{file_path}",
                                               "" ] if hyrax_my_collections_controller_debug_verbose
        ::Deepblue::ProvenanceLogService.entries( id, refresh: true )
        redirect_back fallback_location: [main_app, curation_concern]
      end

      def display_provenance_log_enabled?
        true
      end

      def provenance_log_entries_present?
        provenance_log_entries.present?
      end

      ## end display provenance log

      ## visibility / publish

      def visiblity_changed
        # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                        Deepblue::LoggingHelper.called_from,
        #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
        #                                        "" ] if hyrax_my_collections_controller_debug_verbose
        @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
        if visibility_to_private?
          mark_as_set_to_private
        elsif visibility_to_public?
          mark_as_set_to_public
        end
      end

      def visibility_changed_update
        # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                        Deepblue::LoggingHelper.called_from,
        #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
        #                                        "" ] if hyrax_my_collections_controller_debug_verbose
        if curation_concern.private? && @visibility_changed_to_private
          workflow_unpublish
        elsif curation_concern.public? && @visibility_changed_to_public
          workflow_publish
        end
      end

      def visibility_to_private?
        # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                        Deepblue::LoggingHelper.called_from,
        #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
        #                                        "" ] if hyrax_my_collections_controller_debug_verbose
        return false if curation_concern.private?
        params[PARAMS_KEY]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end

      def visibility_to_public?
        # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                        Deepblue::LoggingHelper.called_from,
        #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
        #                                        "" ] if hyrax_my_collections_controller_debug_verbose
        return false if curation_concern.public?
        params[PARAMS_KEY]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end

      def mark_as_set_to_private
        @visibility_changed_to_public = false
        @visibility_changed_to_private = true
      end

      def mark_as_set_to_public
        @visibility_changed_to_public = true
        @visibility_changed_to_private = false
      end

      ## end visibility / publish

      # def search_builder_class
      #   Hyrax::My::CollectionsSearchBuilder
      # end

      def index
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.collections'), hyrax.my_collections_path
        collection_type_list_presenter
        managed_collections_count
        super
      end

      private

      def search_action_url(*args)
        hyrax.my_collections_url(*args)
      end

      # The url of the "more" link for additional facet values
      def search_facet_path(args = {})
        hyrax.my_dashboard_collections_facet_path(args[:id])
      end

      def collection_type_list_presenter
        @collection_type_list_presenter ||= Hyrax::SelectCollectionTypeListPresenter.new(current_user)
      end

      def managed_collections_count
        @managed_collection_count = Hyrax::Collections::ManagedCollectionsService.managed_collections_count(scope: self)
      end
    end

  end

end
