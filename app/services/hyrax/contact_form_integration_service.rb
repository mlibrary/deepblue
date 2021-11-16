# frozen_string_literal: true

module Hyrax

  module ContactFormIntegrationService

    mattr_accessor :contact_form_integration_service_debug_verbose, default: false

    include ::Deepblue::InitializationConstants

    @@_setup_failed = false
    @@_setup_ran = false

    mattr_accessor :contact_form_controller_debug_verbose, default: false

    mattr_accessor :antispam_timeout_in_seconds, default: 5
    mattr_accessor :contact_form_log_echo_to_rails_logger, default: true
    mattr_accessor :contact_form_log_delivered,  default: true
    mattr_accessor :contact_form_log_spam, default: true

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
