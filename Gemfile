# minimum gem update:
# bundle update --source name_of_gem

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# gem 'hyrax', '2.1.0'
gem 'hyrax', '2.2.4'

gem 'mysql2' # still somehow in 0.x releases...

gem 'config'

# Date range support
gem 'edtf'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.6'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
#
gem 'resque'
gem 'resque-pool'
gem 'resque-web', '~> 0.0.7', require: 'resque_web'

# EZID client from Duke
gem 'ezid-client'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Pinning Rack commit that resolves the large file upload issue
# When 2.0.4 is out this might not be needed anymore
# See: https://tools.lib.umich.edu/jira/browse/DBD-920
#      https://tools.lib.umich.edu/jira/browse/HELIO-1450
# gem 'rack', git: 'https://github.com/rack/rack.git', ref: 'ee01748'

# Begin security vulnerability mitigation
# bundle update --source gem-name
gem 'bootstrap-sass', '~> 3.4.1'
gem 'loofah', '~> 2.2.3'
gem 'rack', '~> 2.0.6'
gem 'rubyzip', '~> 1.2.2'
gem 'sassc', '>= 2.0.0'
gem 'sinatra', '~> 2.0.2'
gem 'sprockets', '~> 3.7.2'
# End security vulnerability mitigation

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  # gem 'rubocop'
  gem 'rubocop', '~> 0.49.1'
  gem 'rubocop-rspec', '~> 1.16.0'
end

gem 'clamav-client'
gem 'down', '~> 4.4'

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '~> 3.0.5'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'devise'
gem 'devise-guests', '~> 0.6'
gem 'omniauth'
gem 'omniauth-cas'
gem 'rsolr', '>= 1.0'
group :development, :test do
  gem 'capybara'
  gem 'chromedriver-helper'
  gem 'database_cleaner'
  gem 'factory_bot', require: false
  gem 'fcrepo_wrapper'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rails-controller-testing'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rspec-retry'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'solr_wrapper', '~> 2.1.0'
end

group :development do
end

gem 'riiif', '~> 1.1'

gem 'okcomputer', '~> 1.17'
