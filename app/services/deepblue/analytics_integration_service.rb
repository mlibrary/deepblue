# frozen_string_literal: true

module Deepblue

  module AnalyticsIntegrationService

    @@_setup_ran = false
    @@_setup_failed = false

    @@event_tracking_debug_verbose = false
    @@event_tracking_excluded_parameters = []
    @@event_tracking_include_request_uri = false

    mattr_accessor :event_tracking_debug_verbose,
                   :event_tracking_excluded_parameters,
                   :event_tracking_include_request_uri

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
