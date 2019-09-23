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
      email_rds_create( current_user: current_user, event_note: event_note )
      # parameters = email_rds_create( current_user: current_user, event_note: event_note, return_email_parameters: true )
      # summary = "#{parameters[:subject]} - #{parameters[:id]}"
      # jira_url = JiraHelper.new_ticket( summary: summary, description: parameters[ :body ] )
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "jira_url=#{jira_url}",
      #                                        "" ]
      # return if jira_url.nil?
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
      email_rds_destroy( current_user: current_user, event_note: event_note )
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
      email_rds_publish( current_user: current_user, event_note: event_note, message: message )
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
      email_rds_unpublish( current_user: current_user, event_note: event_note )
    end

    def workflow_update_before( current_user:, event_note: "" )

    end

    def workflow_update_after( current_user:, event_note: "" )

    end

    end

end
