# frozen_string_literal: true

module Deepblue
 
  module DraftAdminSetService

    @@_setup_ran = false
    @@_setup_failed = false

    mattr_accessor :draft_admin_set_title, default: "Draft works Admin Set"

    def self.draft_admin_set_id
      @@draft_admin_set_id ||= draft_admin_set_id_init
    end

    def self.draft_admin_set
      AdminSet.find draft_admin_set_id
    end

    def self.draft_admin_set_id_init
      draft_admin_set_id = ""
      AdminSet.find_each do |admin_set|
        if admin_set.title.first.eql? draft_admin_set_title 
          draft_admin_set_id = admin_set.id
        end
      end
      draft_admin_set_id
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
