# frozen_string_literal: true

module Deepblue

  # class WorkflowEventError < AbstractEventError
  # end

  module WorkflowEventBehavior

    def workflow_create( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ]
      provenance_create( current_user: current_user, event_note: event_note )
      email_event_create_rds( current_user: current_user, event_note: event_note )
      email_event_create_user( current_user: current_user, event_note: event_note )
      JiraNewTicketJob.perform_later( work_id: id, current_user: current_user )
    end

    def workflow_embargo( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ]
      provenance_embargo( current_user: current_user, event_note: event_note )
    end

    def workflow_destroy( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ]
      provenance_destroy( current_user: current_user, event_note: event_note )
      email_event_destroy_rds( current_user: current_user, event_note: event_note )
    end

    def workflow_publish( current_user:, event_note: "", message: "" )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "message=#{message}",
                                             "" ]
      if respond_to? :date_published
        # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                        Deepblue::LoggingHelper.called_from,
        #                                        "self.date_modified=#{self.date_modified}",
        #                                        "self.date_published=#{self.date_published}",
        #                                        "" ]
        self.date_published = Hyrax::TimeService.time_in_utc
        self.date_modified = DateTime.now
        self.save!
        # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                        Deepblue::LoggingHelper.called_from,
        #                                        "self.date_modified=#{self.date_modified}",
        #                                        "self.date_published=#{self.date_published}",
        #                                        "" ]
      else
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "does not respond to :date_published",
                                               "" ]
      end
      provenance_publish( current_user: current_user, event_note: event_note, message: message )
      email_event_publish_rds( current_user: current_user, event_note: event_note, message: message )
      email_event_publish_user( current_user: current_user, event_note: event_note, message: message )
    end

    def workflow_unembargo( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ]
      provenance_embargo( current_user: current_user, event_note: event_note )
    end

    def workflow_unpublish( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ]
      provenance_unpublish( current_user: current_user, event_note: event_note )
      email_event_unpublish_rds( current_user: current_user, event_note: event_note )
    end

    def workflow_update_before( current_user:, event_note: "" )

    end

    def workflow_update_after( current_user:, event_note: "" )

    end

    end

end
