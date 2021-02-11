# frozen_string_literal: true

module Deepblue

  module FindAndFixService

    mattr_accessor :find_and_fix_service_debug_verbose
    @@find_and_fix_service_debug_verbose = false

    @@_setup_failed = false
    @@_setup_ran = false

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
