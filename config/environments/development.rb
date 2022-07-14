# frozen_string_literal: true

require "email_logger"
require "provenance_logger"
require "devise/fake_auth_header"

require "assets_logger"
require "uglifier_proxy"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  if Rails.configuration.authentication_method == "umich"
    # Middleware to fake authentication header field that would come from apache. ONLY APPLIES TO UMICH AUTHENTICATION
    config.middleware.use FakeAuthHeader
  end

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # rubocop:disable Rails/FilePath
  if Rails.root.join( 'tmp/caching-dev.txt' ).exist?
    puts "Rails caching enabled because file exists: #{Rails.root.join( 'tmp/caching-dev.txt' )}"
    STDOUT.flush
    config.action_controller.perform_caching = true
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    puts "In order to enable caching, create the file:  #{Rails.root.join( 'tmp/caching-dev.txt' )}"
    STDOUT.flush
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end
  # rubocop:enable Rails/FilePath

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # fix for serialization error
  # see: https://github.com/projectblacklight/blacklight/issues/2768
  config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, Hash, HashWithIndifferentAccess]

  config.assets.quiet = true # Suppress logger output for asset requests.
  assets_compile_mode = false
  if assets_compile_mode
    # Compress JavaScripts and CSS.
    config.assets.js_compressor = UglifierProxy.new(harmony: true, source_map: true)
    # config.assets.css_compressor = :sass
    # Do not fallback to assets pipeline if a precompiled asset is missed.
    config.assets.compile = false
  else
    # Debug mode disables concatenation and preprocessing of assets.
    # This option may cause significant delays in view rendering with a large
    # number of complex assets.
    config.assets.debug = true
  end

  config.assets.configure do |env|
    # env.logger = Rails.logger
    env.logger = ASSETS_LOGGER
  end

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Use a real queuing backend for Active Job (needed for testing resque-scheduler)
  # this will force the jobs to be asynchronous (and does not work in dev due to a bug)
  # config.active_job.queue_adapter = :resque

end
