# frozen_string_literal: true

module Hyrax

  module ContactFormIntegrationService

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :contact_form_integration_service_debug_verbose, default: false

    mattr_accessor :contact_form_controller_debug_verbose, default: false

    mattr_accessor :contact_form_send_email,               default: true

    mattr_accessor :antispam_timeout_in_seconds,           default: 5
    mattr_accessor :contact_form_log_echo_to_rails_logger, default: true
    mattr_accessor :contact_form_log_delivered,            default: true
    mattr_accessor :contact_form_log_spam,                 default: true

    mattr_accessor :contact_form_email_passthrough_re,     default: /^.*\@umich.edu$/
    mattr_accessor :contact_form_email_passthrough_enabled, default: true

    mattr_accessor :akismet_enabled,                       default: false
    mattr_accessor :akismet_env_slice_keys,                default: %w{ HTTP_ACCEPT
                                                                        HTTP_ACCEPT_ENCODING
                                                                        REQUEST_METHOD
                                                                        SERVER_PROTOCOL
                                                                        SERVER_SOFTWARE
                                                                      }
    mattr_accessor :akismet_is_spam_only_if_blatant,       default: true

    mattr_accessor :new_google_recaptcha_enabled,          default: false
    mattr_accessor :new_google_recaptcha_just_human_test,  default: false

    def self.akismet_setup
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if contact_form_integration_service_debug_verbose
      # see: https://github.com/jonahb/akismet#basics
      Akismet.api_key = Settings.akismet.api_key
      Akismet.app_url = Settings.akismet.app_url
    end

  end

end
