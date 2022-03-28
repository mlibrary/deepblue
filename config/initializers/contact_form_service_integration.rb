
Hyrax::ContactFormIntegrationService.setup do |config|

  verbose_initialization = false && Rails.configuration.program_name != 'resque-pool'

  puts "\n\nHyrax::ContactFormIntegrationService.setup\n\n" if verbose_initialization

  config.contact_form_integration_service_debug_verbose = false

  config.contact_form_controller_debug_verbose = false

  config.contact_form_send_email               = false

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
  config.akismet_is_spam_only_if_blatant       = true

  config.new_google_recaptcha_enabled          = false
  config.new_google_recaptcha_just_human_test  = false

  case Rails.configuration.hostname
  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
    config.akismet_enabled              = false
    config.new_google_recaptcha_enabled = true
    config.contact_form_send_email      = true
  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
    config.akismet_enabled              = false
    config.new_google_recaptcha_enabled = true
    config.contact_form_send_email      = false
  when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
    config.akismet_enabled              = true
    config.new_google_recaptcha_enabled = true
    config.contact_form_send_email      = false
  when ::Deepblue::InitializationConstants::HOSTNAME_TEST
    config.akismet_enabled              = false
    config.new_google_recaptcha_enabled = false
    config.contact_form_send_email      = true
  when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
    config.akismet_enabled              = true
    config.new_google_recaptcha_enabled = false
    config.contact_form_send_email      = false
  else
    config.akismet_enabled              = false
    config.new_google_recaptcha_enabled = false
    config.contact_form_send_email      = false
  end

  if verbose_initialization
    puts "config.akismet_enabled=#{config.akismet_enabled}"
    puts "Settings.akismet.api_key=#{Settings.akismet.api_key}"
    puts "Settings.akismet.app_url=#{Settings.akismet.app_url}"
  end

  if config.akismet_enabled
    config.akismet_setup
  end

end
