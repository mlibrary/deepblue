# frozen_string_literal: true
# Reviewed: hyrax4
# Reviewed: heliotrope -- in progress

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'

# hyrax-orcid begin
# Try and suppress depreciation warnings
ActiveSupport::Deprecation.silenced = true
# hyrax-orcid end

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

# hyrax-orcid begin
require 'shoulda-matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
# hyrax-orcid end

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!


RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Remove DatabaseCleaner as rails 5.1 handles cleanup better
  # NOTE: need to make sure that this is set true config.use_transactional_fixtures = true
  # config.before(:suite) do
  #   DatabaseCleaner.clean_with(:truncation)
  # end
  #
  # config.before do
  #   DatabaseCleaner.strategy = :transaction
  # end
  #
  # config.before(:each, js: true) do
  #   DatabaseCleaner.strategy = :truncation
  # end
  #
  # # This block must be here, do not combine with the other `before(:each)` block.
  # # This makes it so Capybara can see the database.
  # config.before do
  #   DatabaseCleaner.start
  # end
  #
  # config.after do
  #   DatabaseCleaner.clean
  # end

end

# For system specs

# On system spec failure, don't dump the (binary!) screenshot to the console,
# just save it to disk which is probably ~/tmp/screenshots
ENV['RAILS_SYSTEM_TESTING_SCREENSHOT'] = "simple"
