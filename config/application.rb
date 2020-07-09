# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'
# require 'app/model/concerns/hydra/access_controls/access_right'
require File.join(Gem::Specification.find_by_name("hydra-access-controls").full_gem_path, "app/models/concerns/hydra/access_controls/access_right.rb")
# require_relative '../lib/rack_multipart_buf_size_setter.rb'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# rubocop:disable Rails/Output
module DeepBlueDocs

  class Application < Rails::Application

    # initializer "DeepBlueDocs_initializer", :after => "add_routing_paths" do |app|
    #   # puts "before: app.routes_reloader.paths=#{app.routes_reloader.paths.join("\n")}"
    #   app.routes_reloader.paths.delete_if{ |path| path.include?("resque-web") }
    #   # puts "after: app.routes_reloader.paths=#{app.routes_reloader.paths.join("\n")}"
    # end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    #
    # reference config values like: DeepBlueDocs::Application.config.variable_name
    #
    config.load_timestamp = DateTime.now.freeze
    # puts "Rails.const_defined? 'Console' = #{Rails.const_defined? 'Console'}"
    # puts "Rails.const_defined? 'Server' = #{Rails.const_defined? 'Server'}"
    if Rails.const_defined? 'Console'
      config.program_name = 'rails-console'.freeze
    else
      config.program_name = "#{File.split($PROGRAM_NAME).last}".freeze
    end
    config.program_args = ARGV.dup

    # Chimera configuration goes here
    # config.authentication_method = "generic"
    # config.authentication_method = "iu"
    config.authentication_method = "umich"

    config.generators do |g|
      g.test_framework :rspec, spec: true
    end

    # debug_verbose flags
    config.collection_presenter_debug_verbose = true # COLLECTION_PRESENTER_DEBUG_VERBOSE = true
    config.data_sets_controller_debug_verbose = true # DATA_SETS_CONTROLLER_DEBUG_VERBOSE = true
    config.downloads_controller_debug_verbose = true # DOWNLOADS_CONTROLLER_DEBUG_VERBOSE = true
    config.email_behavior_debug_verbose = true # EMAIL_BEHAVIOR_DEBUG_VERBOSE = true
    config.file_sets_controller_debug_verbose = true # FILE_SETS_CONTROLLER_DEBUG_VERBOSE = true
    config.interpolation_helper_debug_verbose = true # INTERPOLATION_HELPER_DEBUG_VERBOSE = true
    config.works_controller_behavior_debug_verbose = true # WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE = true
    config.work_view_content_service_debug_verbose = false # WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE = false
    config.work_view_content_service_email_templates_debug_verbose = true # WORK_VIEW_CONTENT_SERVICE_EMAIL_TEMPLATES_DEBUG_VERBOSE = true
    config.work_view_content_service_i18n_templates_debug_verbose = false # WORK_VIEW_CONTENT_SERVICE_I18N_TEMPLATES_DEBUG_VERBOSE = true

    # config.middleware.insert_before Rack::Runtime, RackMultipartBufSizeSetter

    ## to configure for Box integration, see config/initalizers/box_integration.rb
    ## to configure for Globus integration, see config/initalizers/globus_service_integration.rb
    ## to configure for Ingest integration, see config/initalizers/ingest_service_integration.rb
    ## to configure for Jira integration, see config/initalizers/jira_integration.rb
    ## to configure for Scheduler integration, see config/initalizers/scheduler_service_integration.rb
    ## to configure for Uptime integration, see config/initalizers/uptime_service_integration.rb

    # config.dbd_version = 'DBDv1'
    config.dbd_version = 'DBDv2'

    config.show_masthead_announcement = false

    # puts "config.time_zone=#{config.time_zone}"
    config.timezone_offset = DateTime.now.offset
    config.timezone_zone = DateTime.now.zone
    config.datetime_stamp_display_local_time_zone = true

    ## ensure tmp directories are defined
    verbose_init = false
    puts "ENV['TMPDIR']=#{ENV['TMPDIR']}" if verbose_init
    puts "ENV['_JAVA_OPTIONS']=#{ENV['_JAVA_OPTIONS']}" if verbose_init
    puts "ENV['JAVA_OPTIONS']=#{ENV['JAVA_OPTIONS']}" if verbose_init
    tmpdir = ENV['TMPDIR']
    if tmpdir.blank? || tmpdir == '/tmp' || tmpdir.start_with?( '/tmp/' )
      tmpdir = File.absolute_path( './tmp/derivatives/' )
      ENV['TMPDIR'] = tmpdir
    end
    ENV['_JAVA_OPTIONS'] = "-Djava.io.tmpdir=#{tmpdir}" if ENV['_JAVA_OPTIONS'].blank?
    ENV['JAVA_OPTIONS'] = "-Djava.io.tmpdir=#{tmpdir}" if ENV['JAVA_OPTIONS'].blank?
    puts "ENV['TMPDIR']=#{ENV['TMPDIR']}"
    puts "ENV['_JAVA_OPTIONS']=#{ENV['_JAVA_OPTIONS']}" if verbose_init
    puts "ENV['JAVA_OPTIONS']=#{ENV['JAVA_OPTIONS']}" if verbose_init
    puts `echo $TMPDIR`.to_s if verbose_init
    puts `echo $_JAVA_OPTIONS`.to_s if verbose_init
    puts `echo $JAVA_OPTIONS`.to_s if verbose_init

    # For properly generating URLs and minting DOIs - the app may not by default
    # Outside of a request context the hostname needs to be provided.
    config.hostname = ENV['APP_HOSTNAME'] || Settings.hostname
    # puts "config.hostname=#{config.hostname}"

    ## begin configure embargo
    config.embargo_enforce_future_release_date = true # now that we have automated embargo expiration
    config.embargo_visibility_after_default_status = ::Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    config.embargo_visibility_during_default_status = ::Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    config.embargo_manage_hide_files = true
    config.embargo_allow_children_unembargo_choice = false
    config.embargo_email_workflow_hostnames = [ 'testing.deepblue.lib.umich.edu',
                                           'staging.deepblue.lib.umich.edu',
                                           'deepblue.lib.umich.edu' ].freeze
    config.embargo_about_to_expire_email_workflow = config.embargo_email_workflow_hostnames.include? config.hostname
    config.embargo_deactivate_email_workflow = config.embargo_email_workflow_hostnames.include? config.hostname
    ## end configure embargo

    ## begin configure email
    if config.program_name != 'resque-pool'
      config.email_debug_verbose = false
    else
      config.email_debug_verbose = false
    end

    config.email_error_alert_addresses = [ 'fritx@umich.edu', 'blancoj@umich.edu' ].freeze

    # see config/settings/production.yml etc. for real values, it's null in development.yml
    config.notification_email = Settings.notification_email
    config.notification_email_contact_form_to = Settings.notification_email_contact_form_to
    # also set initializers/hyrax.rb config.contact_email = Settings.notification_email_contact_us_to
    config.notification_email_contact_us_to = Settings.notification_email_contact_us_to
    config.notification_email_deepblue_to = Settings.notification_email_deepblue_to
    config.notification_email_from = Settings.notification_email_from
    config.notification_email_jira_to = Settings.notification_email_jira_to
    config.notification_email_rds_to = Settings.notification_email_rds_to
    config.notification_email_to = Settings.notification_email_to
    config.notification_email_workflow_to = Settings.notification_email_workflow_to

    config.use_email_notification_for_creation_events = true

    if config.email_debug_verbose
      puts "config.notification_email=#{config.notification_email}"
      puts "config.notification_email_contact_form_to=#{config.notification_email_contact_form_to}"
      puts "config.notification_email_contact_us_to=#{config.notification_email_contact_us_to}"
      puts "config.notification_email_deepblue_to=#{config.notification_email_deepblue_to}"
      puts "config.notification_email_from=#{config.notification_email_from}"
      puts "config.notification_email_jira_to=#{config.notification_email_jira_to}"
      puts "config.notification_email_rds_to=#{config.notification_email_rds_to}"
      puts "config.notification_email_to=#{config.notification_email_to}"
      puts "config.notification_email_workflow_to=#{config.notification_email_workflow_to}"
    end

    # see see config/initalizers/jira_integration.rb for deposit notifications through jira flag
    # end confgure email

    config.upload_max_number_of_files = 100
    config.upload_max_file_size = 5.gigabytes
    config.upload_max_file_size_str = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(config.upload_max_file_size, {})

    config.upload_max_total_file_size = 10.gigabytes
    config.upload_max_total_file_size_str = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(config.upload_max_total_file_size, {})

    config.max_work_file_size_to_download = 10_000_000_000
    config.min_work_file_size_to_download_warn = 1_000_000_000

    ### file upload and ingest
    config.notify_user_file_upload_and_ingest_are_complete = true
    config.notify_managers_file_upload_and_ingest_are_complete = true

    # ingest derivative config
    config.derivative_excluded_ext_set = {}.freeze
    config.derivative_max_file_size = 4_000_000_000 # set to -1 for no limit
    config.derivative_max_file_size_str = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(config.derivative_max_file_size, precision: 3 )


    # URL for logging the user out of Cosign
    config.logout_prefix = "https://weblogin.umich.edu/cgi-bin/logout?"

    # FIXME: This unless reveals bugs. There are places in the app that hard-code the
    #        /data prefix and the tests break when it is set.
    # See references to: DeepBlueDocs::Application.config.relative_url_root
    config.relative_url_root = Settings.relative_url_root unless Rails.env.test?

    # Set the default host for resolving _url methods
    Rails.application.routes.default_url_options[:host] = config.hostname

    # google analytics
    config.google_analytics_embed_url = 'https://datastudio.google.com/embed/reporting/89e13288-f0f5-4cf7-95a1-4587d76208b7/page/6zXD'

    # ordered list metadata config
    config.do_ordered_list_hack = true
    config.do_ordered_list_hack_save = true

    # email config
    config.email_enabled = true
    config.email_log_echo_to_rails_logger = true
    config.action_mailer.smtp_settings ||= {}
    config.action_mailer.smtp_settings.merge!(Settings.rails&.action_mailer&.smtp_settings || {})

    # provenance log config
    config.provenance_log_name = "provenance_#{Rails.env}.log"
    config.provenance_log_path = Rails.root.join( 'log', config.provenance_log_name )
    config.provenance_log_echo_to_rails_logger = true
    config.provenance_log_redundant_events = true

    ## to configure work_view_content, see config/initalizers/work_view_content.rb

    # static content config
    config.static_content_enable_cache = true

    # virus scan config
    config.virus_scan_max_file_size = 4_000_000_000
    config.virus_scan_retry = true
    config.virus_scan_retry_on_error = false
    config.virus_scan_retry_on_service_unavailable = true
    config.virus_scan_retry_on_unknown = false

    # begin rest_api config
    config.rest_api_allow_mutate = true
    config.rest_api_allow_read = true
    # end rest_api config

    # upload log config
    config.upload_log_echo_to_rails_logger = true

    config.key_value_backend = I18n::Backend::KeyValue.new({})
    config.i18n.backend = I18n.backend
    config.after_initialize do
      # puts ""
      # puts "Begin after initialize..."
      # puts
      # http://railscasts.com/episodes/256-i18n-backends?view=asciicast
      I18n.backend = I18n::Backend::Chain.new( config.key_value_backend, I18n.backend )
      config.i18n_backend = I18n.backend
      # puts I18n.backend
      # note that the debug statements in load_email_templates will not go to the log when called from here
      Deepblue::WorkViewContentService.load_email_templates
      # puts "Finished after initialize."
      Deepblue::WorkViewContentService.load_i18n_templates
    end

  end

end
# rubocop:enable Rails/Output
