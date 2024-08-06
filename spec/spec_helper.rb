# frozen_string_literal: true
# # Reviewed: hyrax4 -- in progress
# Reviewed: heliotrope -- in progress

# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

$VERBOSE = nil unless ENV['RUBY_LOUD'] # silence loud Ruby 2.7 deprecations
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
ENV['DATABASE_URL'] = ENV['DATABASE_TEST_URL'] if ENV['DATABASE_TEST_URL']

# Analytics is turned off by default
ENV['HYRAX_ANALYTICS'] = 'false'

require "bundler/setup"

def ci_build?
  ENV['CI']
end

def skip_because( _comment = nil )
  true
end

require 'factory_bot'

if ENV['IN_DOCKER']
  require File.expand_path("config/environment", '../hyrax-webapp')
  db_config = ActiveRecord::Base.configurations[ENV['RAILS_ENV']]
  ActiveRecord::Tasks::DatabaseTasks.create(db_config)

  ActiveRecord::Migrator.migrations_paths = [Pathname.new(ENV['RAILS_ROOT']).join('db', 'migrate').to_s]
  ActiveRecord::Tasks::DatabaseTasks.migrate
  ActiveRecord::Base.descendants.each(&:reset_column_information)
else
  # require 'engine_cart'
  # EngineCart.load_application!
end

# ActiveRecord::Migration.maintain_test_schema!

require 'active_fedora/cleaner'
require 'action_view'
require 'devise'
require 'devise/version'
# require 'mida'
require 'rails-controller-testing'
require 'rspec/rails'
require 'rspec/its'
require 'rspec/matchers'
require 'rspec/active_model/mocks'
require 'equivalent-xml'
require 'equivalent-xml/rspec_matchers'
# hyrax2 & hyrax4 #  require 'database_cleaner'

# require 'hyrax/specs/capybara'
# require 'hyrax/specs/clamav'
require 'hyrax/specs/engine_routes'

# ensure Hyrax::Schema gets loaded is resolvable for `support/` models
Hyrax::Schema # rubocop:disable Lint/Void

# hyrax4 -- Not using postgres, so comment out
# Valkyrie::MetadataAdapter
#   .register(Valkyrie::Persistence::Memory::MetadataAdapter.new, :test_adapter)
# Valkyrie::MetadataAdapter
#   .register(Valkyrie::Persistence::Postgres::MetadataAdapter.new, :postgres_adapter)
# Valkyrie::StorageAdapter.register(
#   Valkyrie::Storage::Disk.new(base_path: Rails.root / 'tmp' / 'test_adapter_uploads'),
#   :test_disk
# )

# Require supporting ruby files from spec/support/ and subdirectories.  Note: engine, not Rails.root context.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

require 'rspec/retry'
require 'support/controller_level_helpers'
require 'webmock/rspec'
allowed_hosts = %w[chrome chromedriver.storage.googleapis.com fcrepo solr]
WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_hosts)

require 'i18n/debug' if ENV['I18N_DEBUG']
require 'byebug' unless ci_build?

require 'hyrax/specs/shared_specs/factories/strategies/json_strategy'
require 'hyrax/specs/shared_specs/factories/strategies/valkyrie_resource'
FactoryBot.register_strategy(:valkyrie_create, ValkyrieCreateStrategy)
FactoryBot.register_strategy(:json, JsonStrategy)
FactoryBot.definition_file_paths = [File.expand_path("../factories", __FILE__)]
FactoryBot.find_definitions

require 'shoulda/matchers'
require 'shoulda/callback/matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

def coverage_needed?
  # ENV['COVERAGE'] || ENV['TRAVIS'] || ENV['COVERALLS_REPO_TOKEN']
  false
end

if coverage_needed?
  require 'coveralls'
  Coveralls.wear! do
    add_filter 'config'
    add_filter 'lib/spec'
    add_filter 'spec'
    # add_filter 'lib/tasks'
  end
end

require 'active_fedora/cleaner'
#require 'rspec/repeat'

def ci_build?
  ENV['TRAVIS'] || ENV['CIRCLE']
end

module EngineRoutes
  def self.included(base)
    base.routes { Hyrax::Engine.routes }
  end

  def main_app
    Rails.application.class.routes.url_helpers
  end
end

# ActiveJob::Base.queue_adapter = :test

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec
    # with.test_framework :minitest
    # with.test_framework :minitest_4
    # with.test_framework :test_unit
    #
    # # Choose one or more libraries:
    # with.library :active_record
    # with.library :active_model
    # with.library :action_controller
    # # Or, choose the following (which implies all of the above):
    # with.library :rails
  end
end

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.

  config.include Shoulda::Matchers::ActiveRecord, type: :model
  config.include Shoulda::Matchers::ActiveModel, type: :form
  config.include Shoulda::Callback::Matchers::ActiveModel
  # config.include Hyrax::Matchers
  config.full_backtrace = true if ci_build?

  config.fixture_path = File.expand_path("../fixtures", __FILE__)
  config.file_fixture_path = File.expand_path("../fixtures", __FILE__)
  config.use_transactional_fixtures = false

  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.before do |example|
    ActiveFedora::Cleaner.clean! if ActiveFedora::Base.count > 0
    # if example.metadata[:type] == :feature && Capybara.current_driver != :rack_test
    #   DatabaseCleaner.strategy = :truncation
    # else
    #   DatabaseCleaner.strategy = :transaction
    #   DatabaseCleaner.start
    # end

    # using :workflow is preferable to :clean_repo, use the former if possible
    # It's important that this comes after DatabaseCleaner.start
    ensure_deposit_available_for(user) if example.metadata[:workflow]
    if example.metadata[:clean_repo]
      # ActiveFedora::Cleaner.clean!
      # The JS is executed in a different thread, so that other thread
      # may think the root path has already been created:
      # ActiveFedora.fedora.connection.send(:init_base_path) if example.metadata[:js]
    end
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
  #   # These two settings work together to allow you to limit a spec run
  #   # to individual examples or groups you care about by tagging them with
  #   # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  #   # get run.
  #   config.filter_run :focus
  #   config.run_all_when_everything_filtered = true
  #
  #   # Allows RSpec to persist some state between runs in order to support
  #   # the `--only-failures` and `--next-failure` CLI options. We recommend
  #   # you configure your source control system to ignore this file.
  #   config.example_status_persistence_file_path = "spec/examples.txt"
  #
  #   # Limits the available syntax to the non-monkey patched syntax that is
  #   # recommended. For more details, see:
  #   #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  #   config.disable_monkey_patching!
  #
  #   # Many RSpec users commonly either run the entire suite or an individual
  #   # file, and it's useful to allow more verbose output when running an
  #   # individual spec file.
  #   if config.files_to_run.one?
  #     # Use the documentation formatter for detailed output,
  #     # unless a formatter has already been configured
  #     # (e.g. via a command-line flag).
  #     config.default_formatter = 'doc'
  #   end
  #
  #   # Print the 10 slowest examples and example groups at the
  #   # end of the spec run, to help surface which specs are running
  #   # particularly slow.
  #   config.profile_examples = 10
  #
  #   # Run specs in random order to surface order dependencies. If you find an
  #   # order dependency and want to debug it, you can fix the order by providing
  #   # the seed, which is printed after each run.
  #   #     --seed 1234
  #   config.order = :random
  #
  #   # Seed global randomization in this process using the `--seed` CLI option.
  #   # Setting this allows you to use `--seed` to deterministically reproduce
  #   # test failures related to randomization by passing the same `--seed` value
  #   # as the one that triggered the failure.
  #   Kernel.srand config.seed


  config.include(ControllerLevelHelpers, type: :view)

  # hyrax-orcid begin
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  # hyrax-orcid end

  config.before(:each, type: :view) do
    initialize_controller_helpers(view)
    # WebMock.disable_net_connect!(allow_localhost: false, allow: 'chromedriver.storage.googleapis.com')
  end

  config.after(:each, type: :view) do
    # WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_hosts)
  end

  config.before(:all, type: :feature) do
    # Assets take a long time to compile. This causes two problems:
    # 1) the profile will show the first feature test taking much longer than it
    #    normally would.
    # 2) The first feature test will trigger rack-timeout
    #
    # Precompile the assets to prevent these issues.
    visit "/assets/application.css"
    visit "/assets/application.js"
  end

  config.after do
    # DatabaseCleaner.clean
    # Ensuring we have a clear queue between each spec.
    ActiveJob::Base.queue_adapter.enqueued_jobs  = []
    ActiveJob::Base.queue_adapter.performed_jobs = []
    # User.group_service.clear
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.include Shoulda::Matchers::Independent

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include EngineRoutes, type: :controller
  config.include Warden::Test::Helpers, type: :request
  config.include Warden::Test::Helpers, type: :feature

  config.before(:each, type: :feature) do |example|
    clean_active_fedora_repository unless
      # trust that clean_repo performed the clean if present
      example.metadata[:clean_repo] ||
      # don't run for adapters other than wings
      (example.metadata[:valkyrie_adapter].present? && example.metadata[:valkyrie_adapter] != :wings_adapter)
  end

  config.append_after(:each, type: :feature) do
    Warden.test_reset!
    Capybara.reset_sessions!
    page.driver.reset!
  end

  config.include Capybara::RSpecMatchers, type: :input
  config.include InputSupport, type: :input
  config.include FactoryBot::Syntax::Methods
  config.include OptionalExample

  config.infer_spec_type_from_file_location!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.formatter = 'LoggingFormatter'
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.profile_examples = 10

  config.before(:example, :clean_repo) do
    # clean_active_fedora_repository unless Hyrax.config.disable_wings
    Hyrax::RedisEventStore.instance.then(&:flushdb)
    # Not needed to clean the Solr core used by ActiveFedora since
    # clean_active_fedora_repository will wipe that core
    Hyrax::SolrService.wipe! if Hyrax.config.query_index_from_valkyrie
  end

  # Use this example metadata when you want to perform jobs inline during testing.
  #
  #   describe '#my_method`, :perform_enqueued do
  #     ...
  #   end
  #
  # If you pass an `Array` of job classes, they will be treated as the filter list.
  #
  #   describe '#my_method`, perform_enqueued: [MyJobClass] do
  #     ...
  #   end
  #
  # Limit to specific job classes with:
  #
  #   ActiveJob::Base.queue_adapter.filter = [JobClass]
  #
  config.around(:example, :perform_enqueued) do |example|
    ActiveJob::Base.queue_adapter.filter =
      example.metadata[:perform_enqueued].try(:to_a)
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = true
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true

    example.run

    ActiveJob::Base.queue_adapter.filter = nil
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = false
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false
  end

  config.before(:example, :index_adapter) do |example|
    allow(Hyrax.config)
      .to receive(:query_index_from_valkyrie)
      .and_return(true)

    adapter_name = example.metadata[:index_adapter]

    allow(Hyrax)
      .to receive(:index_adapter)
      .and_return(Valkyrie::IndexingAdapter.find(adapter_name))
  end

  config.after(:example, :index_adapter) do |example|
    adapter_name = example.metadata[:index_adapter]
    Valkyrie::IndexingAdapter.find(adapter_name).wipe!
  end

  # Configure blacklight to use the valkyrie solr index
  config.around(:example, index_adapter: :solr_index) do |example|
    blacklight_connection_url = CatalogController.blacklight_config.connection_config[:url]
    CatalogController.blacklight_config.connection_config[:url] = Valkyrie::IndexingAdapter.find(:solr_index).connection.options[:url]
    Blacklight.default_index.connection = nil # force reloading of rsolr connection
    example.run
    CatalogController.blacklight_config.connection_config[:url] = blacklight_connection_url
    Blacklight.default_index.connection = nil # force reloading of rsolr connection
  end

  # Prepend this before block to ensure that it runs before other before blocks like clean_repo
  config.prepend_before(:example, :valkyrie_adapter) do |example|
    adapter_name = example.metadata[:valkyrie_adapter]

    allow(Hyrax)
      .to receive(:metadata_adapter)
      .and_return(Valkyrie::MetadataAdapter.find(adapter_name))

    if adapter_name != :wings_adapter
      allow(Hyrax.config).to receive(:disable_wings).and_return(true)
      hide_const("Wings") # disable_wings=true removes the Wings constant
    end
  end

end

# Capybara.register_driver :selenium do |app|
#   profile = Selenium::WebDriver::Firefox::Profile.new
#   client = Selenium::WebDriver::Remote::Http::Default.new
#   #client.timeout = 120 # instead of the default 60
#   client.read_timeout = 120
#   Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile, http_client: client)
# end

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

# Capybara.javascript_driver = :chrome

Capybara.register_driver :javascript do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.configure do |config|
  # config.default_max_wait_time = 10 # seconds
  config.default_driver = :selenium
end
