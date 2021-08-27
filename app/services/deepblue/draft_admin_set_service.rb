# frozen_string_literal: true

module Deepblue
 
  module DraftAdminSetService

    @@_setup_ran = false
    @@_setup_failed = false

    mattr_accessor :draft_admin_set_service_debug_verbose, default: false

    mattr_accessor :draft_admin_set_title, default: "Draft works Admin Set"
    mattr_accessor :draft_workflow_state_name, default: "draft"

    def self.draft_admin_set_id
      @@draft_admin_set_id ||= draft_admin_set_id_init
    end

    def self.draft_admin_set
      id = draft_admin_set_id
      rv = AdminSet.find draft_admin_set_id if id.present?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "admins_set_id=#{draft_admin_set_id}",
                                             "rv=#{rv}",
                                             "" ] if draft_admin_set_service_debug_verbose
      nil
    end

    def self.draft_admin_set_id_init
      AdminSet.find_each do |admin_set|
        rv = admin_set.id
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if draft_admin_set_service_debug_verbose
        return rv if is_draft_admin_set? admin_set
      end
      return ''
    end

    def self.has_draft_admin_set?( obj )
      return false unless obj.respond_to? :admin_set
      is_draft_admin_set? obj.admin_set
    end

    def self.is_draft_admin_set?( admin_set )
      return false if admin_set.blank?
      admin_set.title&.first&.eql? draft_admin_set_title
    end

    def self.is_draft_curation_concern?( curation_concern )
      return false if curation_concern.to_sipity_entity&.workflow_state_name.eql? draft_workflow_state_name
      return false unless curation_concern.admin_set_id == draft_admin_set_id
      return true
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
