# frozen_string_literal: true

module Deepblue

  module ControllerWorkflowEventBehavior

    mattr_accessor :controller_workflow_event_behavior_debug_verbose,
                   default: Rails.configuration.controller_workflow_event_behavior_debug_verbose

    def workflow_create
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "" ] if controller_workflow_event_behavior_debug_verbose
      cc = controller_curation_concern
      cc.workflow_create( current_user: current_user,
                                        event_note: "#{self.class.name} - deposited by #{cc.depositor}" )
    end

    def workflow_destroy
      cc = controller_curation_concern
      return if cc.nil? # because it has been deleted
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "" ] if controller_workflow_event_behavior_debug_verbose
      cc.workflow_destroy( current_user: current_user, event_note: "#{self.class.name}" )
    end

    def workflow_publish
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "" ] if controller_workflow_event_behavior_debug_verbose
      cc = controller_curation_concern
      cc.workflow_publish( current_user: current_user, event_note: "#{self.class.name}" )
    end

    def workflow_unpublish
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "" ] if controller_workflow_event_behavior_debug_verbose
      cc = controller_curation_concern
      cc.workflow_unpublish( current_user: current_user, event_note: "#{self.class.name}" )
    end

    def workflow_update_before( current_user:, event_note: "" )

    end

    def workflow_update_after
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "params[:save_with_files]=#{params[:save_with_files]}",
                                             "t('helpers.action.work.review')=#{t('helpers.action.work.review')}",
                                             "params[:save_with_files].eql? t('helpers.action.work.review')=#{params[:save_with_files].eql? t('helpers.action.work.review')}",
                                             "" ] if controller_workflow_event_behavior_debug_verbose

      is_submit_for_review = params[:save_with_files].eql? t('helpers.action.work.review')
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "is_submit_for_review=#{is_submit_for_review}",
                                             "" ] if controller_workflow_event_behavior_debug_verbose

      cc = controller_curation_concern
      cc.workflow_update_after( current_user: current_user,
                                event_note: "#{self.class.name} - deposited by #{cc.depositor}",
                                submit_for_review: is_submit_for_review )

    end

  end

end
