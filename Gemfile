# minimum gem update:
# bundle update --source name_of_gem

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gemfile_verbose = true
gemfile_bundle_config = nil
exit_log_lines = nil # to disable
exit_log_lines = [] if File.absolute_path( '.' ) =~ /^\/usr\/local\/deploy\/moku\/data\/cache\/builds.*$/
begin
  exit_log_lines << '' unless exit_log_lines.nil?
  path = File.absolute_path '.'
  puts "Absolute path: #{path}" if gemfile_verbose
  exit_log_lines << "Absolute path: #{path}" unless exit_log_lines.nil?
  case path
  when /^\/hydra-dev\/dbd-deploy.*$/
    puts 'Deploying from nectar' if gemfile_verbose
    exit_log_lines << 'Deploying from nectar' unless exit_log_lines.nil?
    gemfile_bundle_config = 'bundle config --local build.libxml-ruby --with-xml2-config=/usr/bin/xml2-config'
  when /^\/usr\/local\/deploy\/moku\/data\/cache\/builds.*$/
    puts 'Deploying via moku' if gemfile_verbose
    exit_log_lines << 'Deploying via moku' unless exit_log_lines.nil?
    exit_log_lines << "ls -l /usr/bin/xml2-config"
    exit_log_lines << `ls -l /usr/bin/xml2-config`
    gemfile_bundle_config = 'bundle config --local build.libxml-ruby --with-xml2-config=/usr/bin/xml2-config'
  when /^\/Users\/.+/
    puts 'Deploying from /Users' if gemfile_verbose
    exit_log_lines << 'Deploying from /Users' unless exit_log_lines.nil?
    exit_log_lines << "ls -l /usr/local/opt/libxml2/bin/xml2-config"
    exit_log_lines << `ls -l /usr/local/opt/libxml2/bin/xml2-config`
    gemfile_bundle_config = 'bundle config --local build.libxml-ruby --with-xml2-config=/usr/local/opt/libxml2/bin/xml2-config'
  end
  if gemfile_verbose
    config_file = File.join( path, '.bundle', 'config')
    puts "Bundle config path: #{config_file}" if gemfile_verbose
    exit_log_lines << "Bundle config path: #{config_file}" unless exit_log_lines.nil?
    contents = open( config_file, "r" ) { |io| io.read }
    puts contents if gemfile_verbose
    exit_log_lines << contents unless exit_log_lines.nil?
  end
  if !gemfile_bundle_config.nil?
    puts "Running bundle config: #{gemfile_bundle_config}" if gemfile_verbose
    exit_log_lines << "Running bundle config: #{gemfile_bundle_config}" unless exit_log_lines.nil?
    bundle_config_rv = `#{gemfile_bundle_config}`
    puts "bundle_config_rv: #{bundle_config_rv}"
    exit_log_lines << "bundle_config_rv: #{bundle_config_rv}" unless exit_log_lines.nil?
  end
rescue Exception => e
  puts "Exception: #{e.to_s}" if gemfile_verbose
end
abort( exit_log_lines.join("\n" ) ) if !exit_log_lines.nil? && exit_log_lines.size > 0

# https://github.com/samvera/hyrax/releases
gem 'hyrax', '2.9.5'
gem 'linkeddata', '<= 3.1.1'
gem 'rdf-rdfa', '< 3.1.1'
gem 'rdf-vocab', '<= 3.1.4'
gem 'libxml-ruby', '~> 3.1.0'

gem 'mysql2' # still somehow in 0.x releases...

gem 'config'

# Date range support
gem 'edtf'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '>= 5.2'
gem 'redis-rails'
gem 'json', '>= 2.1.0'

# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.3.6'
# Use Puma as the app server
gem 'puma', '~> 4.3.5'
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

gem 'resque-scheduler'
gem 'resque-scheduler-web'
gem 'active_scheduler'
gem 'time_difference'

gem 'net-ldap'

# EZID client from Duke
gem 'ezid-client'

# # gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics'
# # gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', tag: 'v0.0.4'
# gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', branch: 'BLUEDOC-1101-pull-updates-from-dbd-to-irus-analytics-gem-2'
# # gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics'

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

gem 'willow_sword', git: 'https://github.com/CottageLabs/willow_sword.git', branch: 'develop'

# gem 'samvera-persona' #, '0.1.7'
# gem 'samvera-persona', :github => 'samvera-labs/samvera-persona', :branch => 'remove-generator-config'
gem 'samvera-persona'

# Begin security vulnerability mitigation
# bundle update --source gem-name
gem 'addressable', '>= 2.8.0'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'carrierwave', '~> 1.3.2'
gem 'loofah', '~> 2.3.1'
gem 'nokogiri', '>= 1.11.4'
gem 'rack', '~> 2.1.4'
gem 'rubyzip', '~> 2.0.0'
gem 'sassc', '>= 2.0.0'
gem 'sinatra', '~> 2.0.2'
gem 'sprockets', '~> 3.7.2'
gem 'websocket-extensions', '>= 0.1.5'
# End security vulnerability mitigation

# To have OAI
gem 'blacklight_oai_provider', '6.0.0.pre1'

# markdown gems
# gem 'kramdown'
gem 'reverse_markdown'
# gem 'redcarpet', '~> 3.3.4'
gem 'redcarpet'

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
# https://github.com/samg/diffy
gem 'diffy'
gem 'jira-ruby', '~> 1.1'
gem 'okcomputer', '~> 1.17'
gem 'omniauth'
gem 'omniauth-cas'
gem 'riiif', '~> 1.1'
gem 'rsolr', '>= 1.0'

# analytics support
# https://github.com/ankane/ahoy
gem 'ahoy_matey' # first-party analytics for Rails
# https://github.com/ankane/chartkick
gem 'chartkick'
# https://github.com/ankane/groupdate
gem 'groupdate'

# Puma server monitoring
# https://github.com/yabeda-rb/yabeda-rails
gem 'yabeda-rails'
# https://github.com/yabeda-rb/yabeda-prometheus
gem 'yabeda-prometheus'
# https://github.com/yabeda-rb/yabeda-puma-plugin
gem 'yabeda-puma-plugin'

# gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics'
# gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', tag: 'v0.0.4'
# gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', branch: 'BLUEDOC-1101-pull-updates-from-dbd-to-irus-analytics-gem-2'
gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics'

# https://github.com/samvera/hydra-role-management
gem 'hydra-role-management'

group :development, :test do
  gem 'capybara'
  gem 'chromedriver-helper'
  gem 'coveralls', require: false
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
  gem 'shoulda-callback-matchers', '~> 1.1.1'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'solr_wrapper', '~> 2.1.0'
end
