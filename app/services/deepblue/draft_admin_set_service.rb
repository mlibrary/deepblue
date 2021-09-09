# frozen_string_literal: true

module Deepblue
 
  module DraftAdminSetService

    NOT_AN_ADMIN_SET_ID = 'NOT_AN_ADMIN_SET_ID' unless const_defined? :NOT_AN_ADMIN_SET_ID

    @@_setup_ran = false
    @@_setup_failed = false

    mattr_accessor :draft_admin_set_service_debug_verbose, default: false

    mattr_accessor :draft_admin_set_title, default: "Draft works Admin Set"
    mattr_accessor :draft_workflow_state_name, default: "draft"

    @@draft_admin_set_id = nil

    def self.draft_admin_set
      return AdminSet.find @@draft_admin_set_id unless @@draft_admin_set_id.nil?
      draft_admin_set_init
      return nil if @@draft_admin_set_id == NOT_AN_ADMIN_SET_ID
      AdminSet.find @@draft_admin_set_id
    end

    def self.draft_admin_set_id
      return @@draft_admin_set_id unless @@draft_admin_set_id.nil?
      draft_admin_set
      return @@draft_admin_set_id
    end

    def self.draft_admin_set_init
      bold_puts = false
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@@draft_admin_set_id='#{@@draft_admin_set_id}'",
                                             "" ], bold_puts: bold_puts if draft_admin_set_service_debug_verbose
      # @@draft_admin_set = nil
      @@draft_admin_set_id = nil
      AdminSet.find_each do |admin_set|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "searching...",
                                               "admin_set=#{admin_set}",
                                               "admin_set.id=#{admin_set.id}",
                                               "admin_set.title.first='#{admin_set.title.first}'",
                                               "draft_admin_set_title='#{draft_admin_set_title}'",
                                               "" ], bold_puts: bold_puts if draft_admin_set_service_debug_verbose
        if admin_set&.title&.first&.eql? draft_admin_set_title
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "found",
                                                 "admin_set=#{admin_set}",
                                                 "admin_set.id=#{admin_set.id}",
                                                 "" ], bold_puts: bold_puts if draft_admin_set_service_debug_verbose
          # @@draft_admin_set = admin_set
          @@draft_admin_set_id = admin_set.id
          return
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "draft admin set not found",
                                             "" ], bold_puts: bold_puts if draft_admin_set_service_debug_verbose
      # @@draft_admin_set = nil
      @@draft_admin_set_id = NOT_AN_ADMIN_SET_ID
      return
    end

    def self.draft_works( email: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if draft_admin_set_service_debug_verbose
      das = draft_admin_set
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "draft_admin_set=#{das}",
                                             "" ] if draft_admin_set_service_debug_verbose
      return [] unless das.present?
      members = das.members
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "draft_admin_set member ids=#{members.map { |m| m.id } }",
                                             "" ] if draft_admin_set_service_debug_verbose
      return [] unless members.present?
      rv = members.select { |work| work.depositor == email }
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv ids=#{rv.map { |m| m.id } }",
                                             "" ] if draft_admin_set_service_debug_verbose
      return rv
    end

    def self.has_draft_admin_set?( obj )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "obj.class.name=#{obj.class.name}",
                                             "obj=#{obj}",
                                             "" ] if draft_admin_set_service_debug_verbose
      return false unless obj.respond_to? :admin_set
      is_draft_admin_set? obj.admin_set
    end

    def self.is_draft_admin_set?( admin_set )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "admin_set.class.name=#{admin_set.class.name}",
                                             "admin_set=#{admin_set}",
                                             "" ] if draft_admin_set_service_debug_verbose
      return false if admin_set.blank?
      # solr documents return arrays when admin_set is called
      if admin_set.is_a? Array
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "admin_set.first='#{admin_set.first}'",
                                               "draft_admin_set_title='#{draft_admin_set_title}'",
                                               "" ] if draft_admin_set_service_debug_verbose
        return admin_set.first == draft_admin_set_title
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "admin_set.id='#{admin_set.id}'",
                                             "draft_admin_set_id='#{draft_admin_set_id}'",
                                             "" ] if draft_admin_set_service_debug_verbose
      admin_set.id == draft_admin_set_id
    end

    def self.is_draft_curation_concern?( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "curation_concern.to_sipity_entity&.workflow_state_name=#{curation_concern.to_sipity_entity&.workflow_state_name}",
                                             "draft_workflow_state_name=#{draft_workflow_state_name}",
                                             "" ] if draft_admin_set_service_debug_verbose
      return true if curation_concern.to_sipity_entity&.workflow_state_name&.eql? draft_workflow_state_name
      rv = has_draft_admin_set? curation_concern
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if draft_admin_set_service_debug_verbose
      return rv
    end

    def self.query_partial_to_remove_works_with_draft_admin_set
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "draft_admin_set_id=#{draft_admin_set_id}",
                                             "draft_admin_set_title=#{draft_admin_set_title}",
                                             "" ] if draft_admin_set_service_debug_verbose
      "{!df=admin_set_sim}NOT \"#{draft_admin_set_title}\""
    end

    def self.setup
      return if @@_setup_ran == true
      @@_setup_ran = true
      begin
        yield self
      rescue Exception => e # rubocop:disable Lint/RescueException
        @@_setup_failed = true
      end
    end

  end

end
