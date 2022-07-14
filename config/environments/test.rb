# frozen_string_literal: true

require "email_logger"
require "provenance_logger"
require "devise/fake_auth_header"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # config.action_controller.asset_host = "file://#{::Rails.root}/public"
  # config.assets.prefix = 'data/assets'

  if Rails.configuration.authentication_method == "umich"
    # Middleware to fake authentication header field that would come from apache. ONLY APPLIES TO UMICH AUTHENTICATION
    config.middleware.use FakeAuthHeader
  end

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # fix for serialization error
  # see: https://github.com/projectblacklight/blacklight/issues/2768
  config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, Hash, HashWithIndifferentAccess]

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # For testing, it is recommended that you use the [built-in `:test` adapter](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters/TestAdapter.html) which stores enqueued and performed jobs, running only those configured to run during test setup. To do this, add the following to `config/environments/test.rb`:
  config.active_job.queue_adapter = :test

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.notification_email = 'fake_notification_email@sample.com'
  config.notification_email_contact_form_to = 'fake_notification_email_contact_form_to@sample.com'
  config.notification_email_contact_us_to = 'fake_notification_email_contact_us_to@sample.com'
  config.notification_email_deepblue = 'fake_notification_email_deepblue@sample.com'
  config.notification_email_from = 'fake_notification_email_from@sample.com'
  config.notification_email_jira_to = 'fake_notification_email_jira_to@sample.com'
  config.notification_email_rds_to = 'fake_notification_email_rds_to@sample.com'
  config.notification_email_to = 'fake_notification_email_to@sample.com'
  config.notification_email_workflow_to = 'fake_notification_email_workflow_to@sample.com'

end
