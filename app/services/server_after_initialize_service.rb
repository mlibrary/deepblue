# frozen_string_literal: true

class ServerAfterInitializeService


  @@_setup_ran = false
  @@_setup_failed = false

  mattr_accessor :server_after_initialize_service_debug_verbose, default: false
  mattr_accessor :server_after_initialize_service_work_view_content_debug_verbose, default: false

  mattr_accessor :server_after_initialize_ran, default: false
  mattr_accessor :server_after_initialize_failed, default: false
  mattr_accessor :server_after_initialize_failed_msgs, default: []

  def self.setup
    return if @@_setup_ran == true
    @@_setup_ran = true
    begin
      yield self
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
    end
  end

  def self.server_after_initialize_callback( config,
             debug_verbose: server_after_initialize_service_debug_verbose,
             debug_verbose_work_view_conent_service: server_after_initialize_service_work_view_content_debug_verbose )
    return if server_after_initialize_ran || server_after_initialize_failed

    puts "Begin server_after_initialize_callback..." if debug_verbose

    ::Hyrax::UserHelper.ensure_hyrax_roles_registered( from_initializer: true ) unless Rails.env.test?
    ::Hyrax::UserHelper.ensure_role_map_registered( from_initializer: true ) unless Rails.env.test?

    # puts if debug_verbose
    # http://railscasts.com/episodes/256-i18n-backends?view=asciicast
    I18n.backend = I18n::Backend::Chain.new( config.key_value_backend, I18n.backend )
    config.i18n_backend = I18n.backend
    puts I18n.backend if debug_verbose
    # note that the debug statements in load_email_templates will not go to the log when called from here
    ::Deepblue::WorkViewContentService.load_email_templates( debug_verbose: debug_verbose_work_view_conent_service )
    ::Deepblue::WorkViewContentService.load_i18n_templates( debug_verbose: debug_verbose_work_view_conent_service )
    ::Deepblue::WorkViewContentService.load_view_templates( debug_verbose: debug_verbose_work_view_conent_service )
    puts "Finished after i18n and view templates load." if debug_verbose

    require 'bolognese' # support for hyrax-doi minting
    Bolognese::Metadata.prepend Bolognese::Readers::HyraxWorkReader
    Bolognese::Metadata.prepend Bolognese::Writers::HyraxWorkWriter

    puts "Before scheduler_autostart" if debug_verbose
    ::Deepblue::SchedulerIntegrationService.scheduler_autostart( debug_verbose: debug_verbose )
    puts "After scheduler_autostart" if debug_verbose

    @@server_after_initialize_ran = true
    puts "Finished server_after_initialize_callback." if debug_verbose
  rescue Exception => e # rubocop:disable Lint/RescueException
    @@server_after_initialize_failed = true
    @@server_after_initialize_failed_msgs << "#{e.class}: #{e.message} at #{e.backtrace[0]}"
    puts @@server_after_initialize_failed_msgs.join "\n"
  end

end
