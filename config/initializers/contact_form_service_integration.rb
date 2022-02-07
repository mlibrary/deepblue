
Hyrax::ContactFormIntegrationService.setup do |config|

  config.contact_form_integration_service_debug_verbose = false

  config.contact_form_controller_debug_verbose = false

  config.antispam_timeout_in_seconds           = 8
  config.contact_form_log_echo_to_rails_logger = true
  config.contact_form_log_delivered            = true
  config.contact_form_log_spam                 = true

  config.akismet_enabled                       = false
  # config.akismet_env_slice_keys                = %w{ HTTP_ACCEPT HTTP_ACCEPT_ENCODING }
  config.akismet_env_slice_keys                = %w{ HTTP_ACCEPT
                                                     HTTP_ACCEPT_ENCODING
                                                     REQUEST_METHOD
                                                     SERVER_PROTOCOL
                                                     SERVER_SOFTWARE
                                                   }

  config.new_google_recaptcha_enabled          = false
  config.new_google_recaptcha_just_human_test  = false

  case Rails.configuration.hostname
  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
    config.new_google_recaptcha_enabled = true
  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
    config.new_google_recaptcha_enabled = true
  when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
    config.new_google_recaptcha_enabled = true
  when ::Deepblue::InitializationConstants::HOSTNAME_TEST
    config.new_google_recaptcha_enabled = false
  when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
    config.new_google_recaptcha_enabled = false
  else
    config.new_google_recaptcha_enabled = false
  end

end
