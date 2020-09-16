# frozen_string_literal: true

module Deepblue

  module ControllerWorkflowEventBehavior

    CONTROLLER_WORKFLOW_EVENT_BEHAVIOR_DEBUG_VERBOSE = false

    def workflow_create
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "" ] if CONTROLLER_WORKFLOW_EVENT_BEHAVIOR_DEBUG_VERBOSE
      curation_concern.workflow_create( current_user: current_user,
                                        event_note: "#{self.class.name} - deposited by #{curation_concern.depositor}" )
    end

    def workflow_destroy
      return if curation_concern.nil? # because it has been deleted
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "" ] if CONTROLLER_WORKFLOW_EVENT_BEHAVIOR_DEBUG_VERBOSE
      curation_concern.workflow_destroy( current_user: current_user, event_note: "#{self.class.name}" )
    end

    def workflow_publish
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "" ] if CONTROLLER_WORKFLOW_EVENT_BEHAVIOR_DEBUG_VERBOSE
      curation_concern.workflow_publish( current_user: current_user, event_note: "#{self.class.name}" )
    end

    def workflow_unpublish
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "" ] if CONTROLLER_WORKFLOW_EVENT_BEHAVIOR_DEBUG_VERBOSE
      curation_concern.workflow_unpublish( current_user: current_user, event_note: "#{self.class.name}" )
    end

    def workflow_update_before( current_user:, event_note: "" )

    end

    def workflow_update_after( current_user:, event_note: "" )

    end

    end

end
