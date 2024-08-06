# frozen_string_literal: true

class ServerAfterInitializeService

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

  mattr_accessor :server_after_initialize_service_debug_verbose, default: false
  mattr_accessor :server_after_initialize_service_work_view_content_debug_verbose, default: false

  mattr_accessor :server_after_initialize_ran, default: false
  mattr_accessor :server_after_initialize_failed, default: false
  mattr_accessor :server_after_initialize_failed_msgs, default: []

  def self.server_after_initialize_callback( config,
             debug_verbose: server_after_initialize_service_debug_verbose,
             debug_verbose_work_view_conent_service: server_after_initialize_service_work_view_content_debug_verbose )

    return if server_after_initialize_ran || server_after_initialize_failed

    puts "Begin server_after_initialize_callback..." if debug_verbose

    ::Hyrax::BrandingHelper.ensure_public_branding_dir_is_linked(debug_verbose: debug_verbose)
    ::Deepblue::IngestAppendContentService.ensure_tmp_script_dir_is_linked(debug_verbose: debug_verbose)

    ::Deepblue::LoggingIntializationService.initialize_logging(debug_verbose: debug_verbose)

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
    ::Deepblue::ThreadedVarService.initialize_cached_threaded_var_semaphores
    ::Deepblue::ThreadedVarService.threaded_var_autoload( debug_verbose: debug_verbose_work_view_conent_service )
    puts "Finished threaded var loading." if debug_verbose

    if Rails.configuration.use_bolognese # Update: hyrax4 # support for hyrax-doi minting
      require 'bolognese'
      Bolognese::Metadata.prepend Bolognese::Readers::HyraxWorkReader
      Bolognese::Metadata.prepend Bolognese::Writers::HyraxWorkWriter
    end

    puts "Before scheduler_autostart" if debug_verbose
    ::Deepblue::SchedulerIntegrationService.scheduler_autostart( debug_verbose: debug_verbose )
    puts "After scheduler_autostart" if debug_verbose

    puts "::Deepblue::IngestIntegrationService.ingest_append_ui_allowed_base_directories=" + ::Deepblue::IngestIntegrationService.ingest_append_ui_allowed_base_directories.pretty_inspect

    puts ">>>>> Begin Google Analytics config <<<<<"
    # Upgrade: hyrax4 # puts "Rails.configuration.enable_google_analytics_3=#{Rails.configuration.enable_google_analytics_3}"
    # Upgrade: hyrax4 # puts "Hyrax.config.google_analytics_id=#{Hyrax.config.google_analytics_id}"
    puts "Hyrax.config.analytic_start_date=#{Hyrax.config.analytic_start_date}"
    puts "Rails.configuration.enable_google_analytics_4=#{Rails.configuration.enable_google_analytics_4}"
    puts "Rails.configuration.google_tag_manager_id=#{Rails.configuration.google_tag_manager_id}"
    puts ">>>>> End Google Analytics config <<<<<"

    @@server_after_initialize_ran = true
    puts "Finished server_after_initialize_callback." if debug_verbose
  rescue Exception => e # rubocop:disable Lint/RescueException
    @@server_after_initialize_failed = true
    @@server_after_initialize_failed_msgs << "#{e.class}: #{e.message} at #{e.backtrace[0]}"
    puts @@server_after_initialize_failed_msgs.join "\n"
  end

end
