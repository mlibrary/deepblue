# frozen_string_literal: true

module Deepblue

  module WorkflowEventBehavior

    mattr_accessor :workflow_event_behavior_debug_verbose,
                            default: Rails.configuration.workflow_event_behavior_debug_verbose
    mattr_accessor :workflow_create_debug_verbose,
                            default: Rails.configuration.workflow_create_debug_verbose
    mattr_accessor :workflow_update_after_debug_verbose,
                            default: Rails.configuration.workflow_update_after_debug_verbose

    def workflow_create( current_user:, event_note: "" )
      debug_verbose = workflow_event_behavior_debug_verbose || workflow_create_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "id=#{id}",
                                             "" ] if debug_verbose
      return if id.blank?
      provenance_create( current_user: current_user, event_note: event_note )
      email_event_create_rds( current_user: current_user, event_note: event_note, was_draft: false )
      email_event_create_user( current_user: current_user, event_note: event_note, was_draft: false )

      # Don't send Jira message if doing a draft work.
      # This gets called by collection create and in that case, the admin_set method is not avaialable.
      is_draft = ::Deepblue::DraftAdminSetService.has_draft_admin_set?( self )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "id=#{id}",
                                             "is_draft=#{is_draft}",
                                             "" ] if debug_verbose
      return if is_draft
      # NewServiceRequestTicketJob.perform_later( work_id: id, current_user: current_user, debug_verbose: debug_verbose )
      ::Deepblue::TicketHelper.new_ticket( cc_id: id,
                                           current_user: current_user,
                                           # test_mode: true,
                                           debug_verbose: debug_verbose )
    end

    def workflow_destroy( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ] if workflow_event_behavior_debug_verbose
      return if id.blank?
      provenance_destroy( current_user: current_user, event_note: event_note )
      email_event_destroy_rds( current_user: current_user, event_note: event_note )

      # Send an email to the user ( depositor )
      is_draft = ::Deepblue::DraftAdminSetService.has_draft_admin_set?( self )
      email_event_destroy_user( current_user: current_user, event_note: event_note, was_draft: is_draft )
    end

    def workflow_embargo( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ] if workflow_event_behavior_debug_verbose
      return if id.blank?
      provenance_embargo( current_user: current_user, event_note: event_note )
    end

    def workflow_publish( current_user:, event_note: "", message: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "message=#{message}",
                                             "" ] if workflow_event_behavior_debug_verbose
      return if id.blank?
      # replace href="/data with href="http://hostname/data
      message = message.gsub(/href="\/data/, "href=\"https://#{Rails.configuration.hostname}/data")
      message = message.gsub("http:", "https:")
      if respond_to? :date_published
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "self.date_modified=#{self.date_modified}",
        #                                        "self.date_published=#{self.date_published}",
        #                                        "" ] if workflow_event_behavior_debug_verbose
        self.date_published = ::Hyrax::TimeService.time_in_utc
        # self.date_modified = DateTime.now
        # self.save!
        self.metadata_touch( validate: true ) if respond_to? :metadata_touch
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
      return if id.blank?
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
      return if id.blank?
      provenance_unembargo( current_user: current_user, event_note: event_note )
    end

    def workflow_unpublish( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ] if workflow_event_behavior_debug_verbose
      return if id.blank?
      provenance_unpublish( current_user: current_user, event_note: event_note )
      email_event_unpublish_rds( current_user: current_user, event_note: event_note )
    end

    def workflow_update_before( current_user:, event_note: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "" ] if workflow_event_behavior_debug_verbose
    end

    def workflow_update_after( current_user:, event_note: "", submit_for_review: false )
      ::Deepblue::DebugLogHelper.log(class_name: self.class.name,
                                     id: id,
                                     event: :workflow_update_after,
                                     event_note: event_note,
                                     current_user: current_user,
                                     submit_for_review: submit_for_review )
      debug_verbose = workflow_event_behavior_debug_verbose || workflow_update_after_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "submit_for_review=#{submit_for_review}",
                                             "" ] if debug_verbose
      return if id.blank?
      return unless submit_for_review
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "About to email RDS, email user, and create service request ticket",
                                             "" ] if debug_verbose
      email_event_create_rds( current_user: current_user, event_note: event_note, was_draft: true )
      email_event_create_user( current_user: current_user, event_note: event_note, was_draft: true )
      # Send this Jira message, if it used to be a draft work, and now it's a regular work
      # NewServiceRequestTicketJob.perform_later( work_id: id, current_user: current_user, debug_verbose: debug_verbose )
      ::Deepblue::TicketHelper.new_ticket( cc_id: id,
                                           current_user: current_user,
                                           # test_mode: true,
                                           debug_verbose: debug_verbose )
    end

  end

end
