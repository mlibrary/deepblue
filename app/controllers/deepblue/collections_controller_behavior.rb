# frozen_string_literal: true

module Deepblue

  module CollectionsControllerBehavior

    include Deepblue::ControllerWorkflowEventBehavior

    PARAMS_KEY = 'collection'

    ## Provenance log

    def provenance_log_update_after
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "@update_attr_key_values=#{@update_attr_key_values}",
      #                                        "" ]
      curation_concern.provenance_log_update_after( current_user: current_user,
                                                    event_note: default_event_note,
                                                    update_attr_key_values: @update_attr_key_values )
    end

    def provenance_log_update_before
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "@update_attr_key_values=#{@update_attr_key_values}",
      #                                        "" ]
      return unless @update_attr_key_values.nil?
      @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[params_key].dup )
    end

    ## end Provenance log

    ## visibility / publish

    def visiblity_changed
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ]
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
      #                                        "" ]
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
      #                                        "" ]
      return false if curation_concern.private?
      params[params_key]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    def visibility_to_public?
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ]
      return false if curation_concern.public?
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
