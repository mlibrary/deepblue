# frozen_string_literal: true

module Deepblue

  module TicketHelper

    STATUS_DRAFT     = 'In draft mode, no ticket needed yet.'.freeze      unless const_defined? :STATUS_DRAFT
    STATUS_EMBARGOED = 'Embargoed, should have a ticket.'.freeze          unless const_defined? :STATUS_EMBARGOED
    STATUS_NOT_OPEN  = 'Visibility not open, no ticket needed.'.freeze    unless const_defined? :STATUS_NOT_OPEN
    STATUS_OPEN      = 'Visibility is open, should have a ticket.'.freeze unless const_defined? :STATUS_OPEN

    TICKET_JOB_STARTING          = 'job starting'.freeze unless const_defined? :TICKET_JOB_STARTING
    TICKET_PENDING               = 'pending'.freeze      unless const_defined? :TICKET_PENDING

    mattr_accessor :ticket_helper_debug_verbose, default: false

    mattr_accessor :ticket_pending_timeout_delta, default: TeamdynamixIntegrationService.ticket_pending_timeout_delta

    def self.curation_notes_admin_link( prefix:, ticket_url: )
      return '' if ticket_url.blank?
      return ticket_url if prefix.blank?
      "#{prefix}#{ticket_url}"
    end

    def self.ensure_not_solr_document( curation_concern )
      return ::PersistHelper.find( curation_concern.id ) if curation_concern.is_a? SolrDocument
      return curation_concern
    end

    def self.new_ticket( curation_concern: nil,
                         cc_id: nil,
                         current_user: nil,
                         force: false,
                         test_mode: false,
                         debug_verbose: ticket_helper_debug_verbose )

      debug_verbose = debug_verbose || ticket_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.present?=#{curation_concern.present?}",
                                             "cc_id=#{cc_id}",
                                             "current_user=#{current_user}",
                                             "force=#{force}",
                                             "test_mode=#{test_mode}",
                                             "" ] if debug_verbose
      curation_concern ||= ::PersistHelper.find( cc_id )
      ::Deepblue::DebugLogHelper.log(class_name: self.class.name,
                                     id: curation_concern.id,
                                     event: :new_ticket,
                                     current_user: current_user,
                                     force: force,
                                     test_mode: test_mode )
      return if ::Deepblue::DraftAdminSetService.has_draft_admin_set? curation_concern
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "curation_concern.ticket=#{curation_concern.ticket}",
                                             "" ] if debug_verbose
      return if curation_concern.ticket.present? && !force
      update_curation_concern_ticket( curation_concern: curation_concern,
                                      update_ticket: TICKET_JOB_STARTING,
                                      test_mode: test_mode )
      return if test_mode
      ::NewServiceRequestTicketJob.perform_later( work_id: curation_concern.id,
                                                  current_user: current_user,
                                                  debug_verbose: false )
    end

    def self.new_ticket_necessary?( curation_concern: )
      return false unless curation_concern.present?
      ticket = curation_concern.ticket
      return true if ticket.blank?
      return true if ticket_pending?( ticket: ticket )
      return false
    end

    def self.new_ticket_if_necessary( curation_concern: nil,
                                      cc_id: nil,
                                      current_user: nil,
                                      send_emails: false,
                                      test_mode: false,
                                      update_if_has_link: true,
                                      debug_verbose: ticket_helper_debug_verbose )

      debug_verbose ||= ticket_helper_debug_verbose
      debug_verbose = debug_verbose || ticket_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.present?=#{curation_concern.present?}",
                                             "cc_id=#{cc_id}",
                                             "current_user=#{current_user}",
                                             "send_emails=#{send_emails}",
                                             "test_mode=#{test_mode}",
                                             "update_if_has_link=#{update_if_has_link}",
                                              "" ] if debug_verbose
      return if cc_id.blank? && curation_concern.blank?
      curation_concern ||= ::PersistHelper.find( cc_id )
      ::Deepblue::DebugLogHelper.log(class_name: self.class.name,
                                     id: curation_concern.id,
                                     event: :new_ticket_if_necessary,
                                     current_user: current_user,
                                     cc_ticket_present: curation_concern.ticket.present? )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "curation_concern.ticket=#{curation_concern.ticket}",
                                             "" ] if debug_verbose
      return unless new_ticket_necessary?( curation_concern:curation_concern )
      rv = ticket_from_curation_concern_notes_admin( curation_concern: curation_concern, debug_verbose: debug_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ticket_from_curation_concern_notes_admin rv=#{rv}",
                                             "" ] if debug_verbose
      ::Deepblue::DebugLogHelper.log(class_name: self.class.name,
                                     id: curation_concern.id,
                                     event: :new_ticket_if_necessary,
                                     current_user: current_user,
                                     cc_admin_notes_has_ticket: rv )
      if rv.present?
        update_curation_concern_ticket( curation_concern: curation_concern,
                                        test_mode: test_mode,
                                        update_ticket: rv ) if update_if_has_link
        return
      end
      curation_concern = ensure_not_solr_document curation_concern
      # tombstoned?
      cc_published = curation_concern.published?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.published?=#{cc_published}",
                                             "" ] if debug_verbose
      ::Deepblue::DebugLogHelper.log(class_name: self.class.name,
                                     id: curation_concern.id,
                                     event: :new_ticket_if_necessary,
                                     current_user: current_user,
                                     cc_published?: cc_published )
      return if cc_published
      is_draft = ::Deepblue::DraftAdminSetService.has_draft_admin_set? curation_concern
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "is_draft=#{is_draft}",
                                             "" ] if debug_verbose
      ::Deepblue::DebugLogHelper.log(class_name: self.class.name,
                                     id: curation_concern.id,
                                     event: :new_ticket_if_necessary,
                                     current_user: current_user,
                                     cc_is_draft: is_draft )
      return if is_draft
      embargoed_or_open = curation_concern.embargoed? || curation_concern.visibility == 'open'
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "embargoed_or_open=#{embargoed_or_open}",
                                             "" ] if debug_verbose
      ::Deepblue::DebugLogHelper.log(class_name: self.class.name,
                                     id: curation_concern.id,
                                     event: :new_ticket_if_necessary,
                                     current_user: current_user,
                                     cc_embargoed_or_open: embargoed_or_open )
      return unless embargoed_or_open
      # Assume the email notification hasn't been sent, if it has, then set send_emails to false
      ::Deepblue::DebugLogHelper.log(class_name: self.class.name,
                                     id: curation_concern.id,
                                     event: :new_ticket_if_necessary,
                                     event_note: "new ticket is necessary",
                                     current_user: current_user )
      if send_emails && !test_mode
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "About to email RDS, email user, and create service request ticket",
                                               "" ] if debug_verbose
        curation_concern.email_event_create_rds( current_user: current_user, was_draft: true )
        curation_concern.email_event_create_user( current_user: curation_concern.depositor, was_draft: true )
      end
      new_ticket( curation_concern: curation_concern,
                  current_user: current_user,
                  test_mode: test_mode,
                  debug_verbose: debug_verbose )
    end

    def self.run_ticket_job?( curation_concern:, debug_verbose: ticket_helper_debug_verbose )
      debug_verbose = debug_verbose || ticket_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if debug_verbose
      # return false if curation_concern.ticket.present?
      # return false unless curation_concern.pending_publication?
      # return true
      return false
    end

    def self.ticket_pending?( ticket: )
      # return TICKET_PENDING == ticket
      return false if ticket.blank?
      return true if ticket.start_with? TICKET_PENDING
      return false
    end

    def self.ticket_pending_init
      rv = "#{TICKET_PENDING} as of #{DateTime.now}"
      return rv
    end

    def self.ticket_pending_timeout?( ticket: )
      return false unless ticket_pending?( ticket: ticket )
      return true if TICKET_PENDING == ticket
      match = ticket.match( /^.*pending as of (\d.+)$/ )
      return false if match.blank?
      as_of = match[1]
      return false if as_of.blank?
      begin
        as_of = DateTime.parse( as_of )
        as_of = as_of + ticket_pending_timeout_delta
        return true if as_of < DateTime.now
      rescue Exception => e
        # puts e
        return false
      end
      return false
    end

    def self.ticket_status( curation_concern:, raw_ticket: nil, debug_verbose: ticket_helper_debug_verbose )
      debug_verbose = debug_verbose || ticket_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "raw_ticket=#{raw_ticket}",
                                             "" ] if debug_verbose
      return raw_ticket if raw_ticket.present?
      rv = ticket_from_curation_concern_notes_admin( curation_concern: curation_concern, debug_verbose: debug_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ticket_from_curation_concern_notes_admin rv=#{rv}",
                                             "" ] if debug_verbose
      return rv if rv.present?
      if ::Deepblue::DraftAdminSetService.has_draft_admin_set? curation_concern
        rv = STATUS_DRAFT
      elsif curation_concern.embargoed? # TODO: validate
        rv = STATUS_EMBARGOED
      elsif curation_concern.visibility == 'open'
        rv = STATUS_OPEN
      else
        rv = STATUS_NOT_OPEN
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ticket_status rv=#{rv}",
                                             "" ] if debug_verbose
      return rv
    end

    def self.ticket_from_curation_concern_notes_admin( curation_concern:, debug_verbose: ticket_helper_debug_verbose )
      debug_verbose = debug_verbose || ticket_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if debug_verbose
      return nil unless curation_concern.respond_to? :curation_notes_admin
      prefix1 = Regexp.escape ::Deepblue::TeamdynamixIntegrationService.admin_note_ticket_prefix
      prefix2 = Regexp.escape ::Deepblue::JiraHelper.admin_note_ticket_prefix
      prefix = "(#{prefix1}|#{prefix2})"
      search_re = /^.*#{prefix}([^\s]+).*$/
      curation_concern.curation_notes_admin.each do |note|
        if note =~ search_re
          ticket = Regexp.last_match(2)
          return ticket
        end
      end
      return nil
    end

    def self.start_new_ticket_job( curation_concern:, msg_handler: )
      is_draft = ::Deepblue::DraftAdminSetService.has_draft_admin_set? curation_concern
      return false if is_draft
      cc_ticket_equals_ticket_job_starting = TICKET_JOB_STARTING == curation_concern.ticket
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "curation_concern.id=#{curation_concern.id}",
                               "curation_concern.ticket=#{curation_concern.ticket}",
                               "is_draft=#{is_draft}",
                               "(TICKET_JOB_STARTING == curation_concern.ticket)=#{cc_ticket_equals_ticket_job_starting}",
                               "" ] if msg_handler.debug_verbose
      unless cc_ticket_equals_ticket_job_starting
        msg = "Start new ticket job? false -- curation_concern.ticket=#{curation_concern.ticket}"
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "msg=#{msg}",
                                 "" ] if msg_handler.debug_verbose
        msg_handler.msg_verbose msg unless cc_ticket_equals_ticket_job_starting
        return false
      end
      msg = 'Start new ticket job? true'
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "msg=#{msg}",
                               "" ] if msg_handler.debug_verbose
      msg_handler.msg_verbose msg
      update_curation_concern_ticket( curation_concern: curation_concern,
                                      update_ticket: TicketHelper.ticket_pending_init,
                                      msg_handler: msg_handler )
      return true # actually create the ticket
    end

    def self.update_curation_concern_with_ticket_url( curation_concern:, msg_handler:, prefix:, ticket_url: )
      note = curation_notes_admin_link( prefix: prefix, ticket_url: ticket_url )
      if curation_concern.respond_to? :add_curation_note_admin
        curation_concern.add_curation_note_admin( note: note, persist: false, msg_handler: msg_handler ) if note.present?
      else
        msg_handler.warning "curation concern #{curation_concern.id} does not respond to :add_curation_note_admin"
        msg_handler.warning "skipping add of curation note: #{note}"
      end
      update_curation_concern_ticket( curation_concern: curation_concern,
                                      update_ticket: ticket_url,
                                      msg_handler: msg_handler )
    end

    def self.update_curation_concern_ticket( curation_concern:, msg_handler: nil, test_mode: false, update_ticket: )
      ::Deepblue::DebugLogHelper.log( class_name: self.class.name,
                                      id: curation_concern.id,
                                      event: :update_curation_concern_ticket,
                                      test_mode: test_mode,
                                      update_ticket: update_ticket )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "curation_concern.ticket=#{curation_concern.ticket}",
                                             "test_mode=#{test_mode}",
                                             "update_ticket=#{update_ticket}",
                                             "" ] if msg_handler.blank? && ticket_helper_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "curation_concern.id=#{curation_concern.id}",
                               "curation_concern.ticket=#{curation_concern.ticket}",
                               "test_mode=#{test_mode}",
                               "update_ticket=#{update_ticket}",
                               "" ] if msg_handler.present? && msg_handler.debug_verbose
      curation_concern = ensure_not_solr_document curation_concern
      return if test_mode
      # curation_concern.date_modified = DateTime.now
      curation_concern.ticket = update_ticket
      # curation_concern.save!
      curation_concern.metadata_touch( validate: true )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "curation_concern.ticket=#{curation_concern.ticket}",
                                             "" ] if msg_handler.blank? && ticket_helper_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "curation_concern.id=#{curation_concern.id}",
                               "curation_concern.ticket=#{curation_concern.ticket}",
                               "" ] if msg_handler.present? && msg_handler.debug_verbose
    end

  end

end
