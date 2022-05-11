# frozen_string_literal: true

module Deepblue

  module CollectionsControllerBehavior

    mattr_accessor :collection_controller_behavior_debug_verbose,
                   default: Rails.configuration.collections_controller_behavior_debug_verbose

    include ::Deepblue::ControllerWorkflowEventBehavior

    PARAMS_KEY = 'collection' unless const_defined? :PARAMS_KEY

    def controller_curation_concern
      @controller_curation_concern ||= find_curation_concern
    end

    def find_curation_concern
      cc = @collection
      return cc unless cc.blank?
      cc = curation_concern
      return cc if cc.blank?
      return ::PersistHelper.find(cc.id) if cc.is_a? SolrDocument
      cc
    end

    ## Provenance log

    def provenance_log_update_after
      cc = controller_curation_concern
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "@update_attr_key_values=#{@update_attr_key_values}",
      #                                        "" ] if collection_controller_behavior_debug_verbose
      cc.provenance_log_update_after( current_user: current_user,
                                      event_note: default_event_note,
                                      update_attr_key_values: @update_attr_key_values )
    end

    def provenance_log_update_before
      cc = controller_curation_concern
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "@update_attr_key_values=#{@update_attr_key_values}",
      #                                        "" ] if collection_controller_behavior_debug_verbose
      return unless @update_attr_key_values.nil?
      @update_attr_key_values = cc.provenance_log_update_before( form_params: params[params_key].dup )
    end

    ## end Provenance log

    ## visibility / publish

    def visiblity_changed
      cc = controller_curation_concern
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ] if collection_controller_behavior_debug_verbose
      @update_attr_key_values = cc.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
      if visibility_to_private?
        mark_as_set_to_private
      elsif visibility_to_public?
        mark_as_set_to_public
      end
    end

    def visibility_changed_update
      cc = controller_curation_concern
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ] if collection_controller_behavior_debug_verbose
      if cc.private? && @visibility_changed_to_private
        workflow_unpublish
      elsif cc.public? && @visibility_changed_to_public
        workflow_publish
      end
    end

    def visibility_to_private?
      cc = controller_curation_concern
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ] if collection_controller_behavior_debug_verbose
      return false if cc.private?
      params[params_key]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    def visibility_to_public?
      cc = controller_curation_concern
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ] if collection_controller_behavior_debug_verbose
      return false if cc.public?
      params[params_key]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
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

  end

end
