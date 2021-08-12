# frozen_string_literal: true

module Deepblue

  # class WorkflowEventError < AbstractEventError
  # end

  module WorkflowEventBehavior

    mattr_accessor :workflow_event_behavior_debug_verbose,
                   default: ::DeepBlueDocs::Application.config.workflow_event_behavior_debug_verbose

    def workflow_create( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "id=#{id}",
                                             "" ] if workflow_event_behavior_debug_verbose
      return if id.blank?
      provenance_create( current_user: current_user, event_note: event_note )
      email_event_create_rds( current_user: current_user, event_note: event_note )
      email_event_create_user( current_user: current_user, event_note: event_note )

      # Don't send Jira message if doing a draft work.
      # This gets called by collection create and in that case, the admin_set method is not avaialable.
      JiraNewTicketJob.perform_later( work_id: id, current_user: current_user ) unless ( self.respond_to?(:admin_set) ) && ( self.admin_set.title.first.eql? ::Deepblue::EmailHelper.t("hyrax.admin_set.name") )
    end

    def workflow_embargo( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ] if workflow_event_behavior_debug_verbose
      provenance_embargo( current_user: current_user, event_note: event_note )
    end

    def workflow_destroy( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ] if workflow_event_behavior_debug_verbose
      provenance_destroy( current_user: current_user, event_note: event_note )
      email_event_destroy_rds( current_user: current_user, event_note: event_note )
    end

    def workflow_publish( current_user:, event_note: "", message: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "message=#{message}",
                                             "" ] if workflow_event_behavior_debug_verbose
      if respond_to? :date_published
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "self.date_modified=#{self.date_modified}",
        #                                        "self.date_published=#{self.date_published}",
        #                                        "" ] if workflow_event_behavior_debug_verbose
        self.date_published = Hyrax::TimeService.time_in_utc
        self.date_modified = DateTime.now
        self.save!
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "self.date_modified=#{self.date_modified}",
        #                                        "self.date_published=#{self.date_published}",
        #                                        "" ] if workflow_event_behavior_debug_verbose
      else
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "does not respond to :date_published",
                                               "" ] if workflow_event_behavior_debug_verbose
      end
      provenance_publish( current_user: current_user, event_note: event_note, message: message )
      doi_mint( current_user: current_user, event_note: event_note )
      globus_clean_download_then_recopy if respond_to? :globus_clean_download_then_recopy
      email_event_publish_rds( current_user: current_user, event_note: event_note, message: message )
      email_event_publish_user( current_user: current_user, event_note: event_note, message: message )
    end

    def workflow_publish_doi_mint( current_user:, event_note: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "respond_to? :doi_mint=#{respond_to?( :doi_mint )}",
                                             "" ] if workflow_event_behavior_debug_verbose
      return unless respond_to? :doi_mint
      return unless ::Deepblue::DoiMintingService.doi_mint_on_publication_event
      doi_mint( current_user: current_user, event_note: event_note )
    end

    def workflow_unembargo( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ] if workflow_event_behavior_debug_verbose
      provenance_embargo( current_user: current_user, event_note: event_note )
    end

    def workflow_unpublish( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ] if workflow_event_behavior_debug_verbose
      provenance_unpublish( current_user: current_user, event_note: event_note )
      email_event_unpublish_rds( current_user: current_user, event_note: event_note )
    end

    def workflow_update_before( current_user:, event_note: "" )

    end

    def workflow_update_after( current_user:, event_note: "", was_draft: false )
      #Send this Jira message, if it used to be a draft work, and now it's a regular work
      JiraNewTicketJob.perform_later( work_id: id, current_user: current_user ) if was_draft
    end

  end

end
