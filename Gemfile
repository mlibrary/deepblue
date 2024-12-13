# frozen_string_literal: true
# NOTE: minimum gem update:
# bundle update --source name_of_gem

# Attempts to determine if a global gem source has ready been added by another Gemfile
if @sources.global_rubygems_source == Bundler::SourceList.new.global_rubygems_source
  Bundler.ui.info '[Dassie] Adding global rubygems source.'
  source 'https://rubygems.org'
else
  Bundler.ui.info "[Dassie] Global rubygems source already set: #{@sources.global_rubygems_source.inspect}"
end

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

current_path = File.absolute_path '.'

gemfile_abort_to_report = false
gemfile_verbose = false
gemfile_bundle_config = nil
exit_log_lines = nil # to disable
exit_log_lines = [] if File.absolute_path( '.' ) =~ /^\/usr\/local\/deploy\/moku\/data\/cache\/builds.*$/
begin
  line = '';(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
  line = 'begin gemfile extra config:';(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
  line = "Absolute path: #{current_path}";(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
  line = "xml2-config --version";(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
  line = `xml2-config --version`;(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
  case current_path
  when /^\/hydra-dev\/dbd-deploy.*$/
    line = 'Deploying from nectar';(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
    gemfile_bundle_config = 'bundle config --local build.libxml-ruby --with-xml2-config=/usr/bin/xml2-config'
  when /^\/usr\/local\/deploy\/moku\/data\/cache\/builds.*$/
    line = 'Deploying via moku';(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
    line = "ls -l /usr/bin/xml2-config";(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
    line = `ls -l /usr/bin/xml2-config`;(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
    gemfile_bundle_config = 'bundle config --local build.libxml-ruby --with-xml2-config=/usr/bin/xml2-config'
  when /^\/Users\/.+/
    line = 'Deploying from /Users';(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
    # line = "ls -l /usr/bin/xml2-config";(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
    # line = `ls -l /usr/bin/xml2-config`;(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
    # gemfile_bundle_config = 'bundle config --local build.libxml-ruby --with-xml2-config=/usr/local/opt/libxml2/bin/xml2-config'
    gemfile_bundle_config = 'bundle config --local build.libxml-ruby --with-xml2-config=/usr/bin/xml2-config --with-cflags="-Wno-error=implicit-function-declaration'
  end
  if gemfile_verbose
    config_file = File.join( current_path, '.bundle', 'config')
    line = "Bundle config path: #{config_file}";(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
    contents = File.open( config_file, "r" ) { |io| io.read };(puts contents if gemfile_verbose;exit_log_lines << contents unless exit_log_lines.nil?)
  end
  if !gemfile_bundle_config.nil?
    line = "Running bundle config: #{gemfile_bundle_config}";(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
    line = `#{gemfile_bundle_config}`;(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
  end
  line = 'end gemfile extra config:';(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
  line = '';(puts line if gemfile_verbose);(exit_log_lines << line unless exit_log_lines.nil?)
rescue Exception => e
  puts "Exception: #{e.to_s}" if gemfile_verbose
end
abort( exit_log_lines.join("\n" ) ) if gemfile_abort_to_report && !exit_log_lines.nil? && exit_log_lines.size > 0

gem 'file_exists', '~> 0.2.0'

gem 'valkyrie', '~> 3.1'

##############################################################################
#
# hyrax
#
##############################################################################
# https://github.com/samvera/hyrax/releases
# gem 'hyrax', '3.0.2' # hyrax v3 update
# gem 'hyrax', '3.1'   # hyrax v3.1 update
#gem 'hyrax', '4.0'    # hyrax 4 update
gem 'hyrax', '5.0.1'   # hyrax5 update

gem 'active-fedora', '~> 14.0' # hyrax5 update
gem 'almond-rails', '~> 0.1' # hyrax5 update
gem 'awesome_nested_set', '~> 3.1' # hyrax5 update
gem 'blacklight', '~> 7.29' # hyrax5 update
gem 'blacklight-gallery', '~> 4.0' # hyrax5 update

gem 'breadcrumbs_on_rails', '~> 3.0'
gem 'browse-everything', '>= 0.16', '< 2.0'
gem 'carrierwave', '~> 1.0'
# spec.add_dependency 'clipboard-rails', '~> 1.5'
# spec.add_dependency 'concurrent-ruby', '~> 1.0'
# spec.add_dependency 'connection_pool', '~> 2.4'
# spec.add_dependency 'draper', '~> 4.0'
# spec.add_dependency 'dry-logic', '~> 1.5'
# spec.add_dependency 'dry-container', '~> 0.11'
# spec.add_dependency 'dry-events', '~> 1.0', '>= 1.0.1'
# spec.add_dependency 'dry-monads', '~> 1.6'
# spec.add_dependency 'dry-validation', '~> 1.10'
gem 'faraday', '2.9.1' # Pinned to avoid errors from calling start_with? on RDF::Value
# spec.add_dependency 'flipflop', '~> 2.3'
# # Pin more tightly because 0.x gems are potentially unstable
# spec.add_dependency 'flot-rails', '~> 0.0.6'
# spec.add_dependency 'font-awesome-rails', '~> 4.2'
# spec.add_dependency 'google-analytics-data', '~> 0.6'
# spec.add_dependency 'hydra-derivatives', '~> 3.3'
# spec.add_dependency 'hydra-editor', '~> 6.0'
# spec.add_dependency 'hydra-file_characterization', '~> 1.1'
# spec.add_dependency 'hydra-head', '~> 12.0'
# spec.add_dependency 'hydra-works', '>= 0.16'
# spec.add_dependency 'iiif_manifest', '>= 0.3', '< 2.0'
# spec.add_dependency 'json-schema' # for Arkivo
# spec.add_dependency 'legato', '~> 0.3'
# gem 'linkeddata' # Required for getting values from geonames
# spec.add_dependency 'mailboxer', '~> 0.12'
# spec.add_dependency 'nest', '~> 3.1'
# spec.add_dependency 'noid-rails', '~> 3.0'
# spec.add_dependency 'oauth'
# spec.add_dependency 'oauth2', '~> 1.2'
# spec.add_dependency 'openseadragon'
# spec.add_dependency 'posix-spawn'
# spec.add_dependency 'qa', '~> 5.5', '>= 5.5.1' # questioning_authority
# spec.add_dependency 'rails_autolink', '~> 1.1'
# spec.add_dependency 'rdf-rdfxml' # controlled vocabulary importer
gem 'rdf-vocab', '~> 3.0'
gem 'redis', '~> 4.0'
# spec.add_dependency 'redis-namespace', '~> 1.5'
# spec.add_dependency 'redlock', '>= 0.1.2', '< 2.0'
# spec.add_dependency 'reform', '~> 2.3'
# spec.add_dependency 'reform-rails', '~> 0.2.0'
# spec.add_dependency 'retriable', '>= 2.9', '< 4.0'
# spec.add_dependency 'signet'
# spec.add_dependency 'tinymce-rails', '~> 5.10'
# gem 'valkyrie', '>= 3.1'
# spec.add_dependency 'view_component', '~> 2.74.1' # Pin until blacklight is updated with workaround for https://github.com/ViewComponent/view_component/issues/1565
gem 'sprockets', '3.7.2' # 3.7.3 fails feature specs
gem 'sass-rails', '~> 6.0'
# spec.add_dependency 'select2-rails', '~> 3.5'

#hyrax5 - begin from .dassie/Gemfile
gem 'bootsnap', '>= 1.1.0', require: false
gem 'bootstrap', '~> 4.0'
gem 'coffee-rails', '~> 4.2'
gem 'dalli'
gem 'devise'
gem 'devise-guests', '~> 0.8'
#
# # Required because grpc and google-protobuf gem's binaries are not compatible with Alpine Linux.
# # To install the package in Alpine: `apk add ruby-grpc`
# # The pinned versions should match the version provided by the Alpine packages.
# if RUBY_PLATFORM =~ /musl/
#   path '/usr/lib/ruby/gems/3.2.0' do
#     gem 'google-protobuf', '~> 3.24.4', force_ruby_platform: true
#     gem 'grpc', '~> 1.59.3', force_ruby_platform: true
#   end
# end
#
# gemspec name: 'hyrax', path: ENV.fetch('HYRAX_ENGINE_PATH', '..')
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'pg', '~> 1.3'
gem 'puma'
gem 'rails', '~> 6.1'
gem 'riiif', '~> 2.1'
gem 'rsolr', '>= 1.0', '< 3'
# gem 'sass-rails', '~> 6.0'
# gem 'sidekiq', '~> 6.4'
gem 'turbolinks', '~> 5'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'uglifier', '>= 1.3.0'
#
group :development do
   gem 'better_errors' # add command line in browser when errors
   gem 'binding_of_caller' # deeper stack trace used by better errors

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
   gem 'web-console', '>= 3.3.0'
   gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
#
group :development, :test do
  gem 'debug', '>= 1.0.0'
  gem 'pry-doc'
  gem 'pry-rails'
  gem 'pry-rescue'
  # gem 'database_cleaner-active_record'  # Remove DatabaseCleaner as rails 5.1 handles cleanup better
end
#hyrax5 end from .dassie/Gemfile

#hyrax5 - begin updates from comparing Gemfile.lock
gem 'ebnf', '~>2.4.0'
gem 'launchy'
gem 'ldp', '>= 1.2.1'
gem 'linkeddata', '>=3.3.1'
gem 'rack-linkeddata'
gem 'rack-rdf', '3.3.0'
gem 'rdf-ldp', '>=2.1'
gem 'rdf-n3', '>=3.3'
#hyrax5 - end updates from comparing Gemfile.lock

#hyrax5 - gem 'solrizer',    '>= 4.1.0'  # because solrizer is no longer included in Hyrax 3
#hyrax5 - gem 'linkeddata',  '<= 3.1.1'  # need to look into latest version of this
#hyrax5 - gem 'rdf-rdfa',    '< 3.1.1'   # need to look into latest version of this
#hyrax5 - gem 'rdf-vocab',   '<= 3.1.4'  # need to look into latest version of this
# gem 'libxml-ruby', '~> 3.1.0'

# gem 'dropbox_api', '0.1.18' # pin this as it breaks on later versions causing browse everything with dropbox to fail

gem 'mysql2' # unless current_path.include? "blancoj"

gem 'config'

# Date range support
gem 'edtf'

gem 'redis-rails'
gem 'json', '>= 2.1.0'
# gem 'bolognese', '~> 1.8', '>= 1.8.6'
# gem 'maremma', git: 'https://github.com/mlibrary/maremma'
# gem 'bolognese', git: 'https://github.com/mlibrary/bolognese'

# gem 'rails-html-sanitizer', '>= 1.4.4'
gem 'rails-html-sanitizer'

# Use sqlite3 as the database for Active Record
# gem 'sqlite3', '~> 1.3.6'
gem 'sqlite3', '~> 1.5.0'
# Use Puma as the app server
# gem 'puma', '~> 5.6.7'
#hyrax5 - gem 'puma', '>= 5.6.7'
# Use SCSS for stylesheets
# gem 'sass-rails', '~> 5.0'
#hyrax5 - gem 'sass-rails', '~> 6.0'

# Use CoffeeScript for .coffee assets and views
#hyrax5 - gem 'coffee-rails', '~> 4.2'
# gem 'coffee-rails', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
#hyrax5 - gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
#hyrax5 - gem 'jbuilder', '>= 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '< 5.0'
#hyrax5 - gem 'redis'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Pinning Rack commit that resolves the large file upload issue
# When 2.0.4 is out this might not be needed anymore
# See: https://tools.lib.umich.edu/jira/browse/DBD-920
#      https://tools.lib.umich.edu/jira/browse/HELIO-1450
# gem 'rack', git: 'https://github.com/rack/rack.git', ref: 'ee01748'

#hyrax5 - gem 'willow_sword', git: 'https://github.com/CottageLabs/willow_sword.git', branch: 'develop'

##############################################################################
# APTrust
##############################################################################
# see: https://github.com/tipr/bagit
gem 'bagit'
gem 'minitar', '~>0.8'
# gem 'minitar', '>= 0.8'
gem 'aws-sdk-s3', '~> 1'
gem 'typhoeus', '~> 1.1'

# ##############################################################################
# #
# # hyrax
# #
# ##############################################################################
# # https://github.com/samvera/hyrax/releases
# # gem 'hyrax', '3.0.2' # hyrax v3 update
# # gem 'hyrax', '3.1'   # hyrax v3.1 update
# #gem 'hyrax', '4.0'    # hyrax 4 update
# gem 'hyrax', '5.0.1'   # hyrax5 update

##############################################################################
#
# Deepblue Data
#
##############################################################################

# To have OAI
# gem 'blacklight_oai_provider', '6.0.0.pre1'
# gem 'blacklight_oai_provider', "~> 7.0.2"
gem 'blacklight_oai_provider', ">= 7.0.2"

gem 'solrizer',    '>= 4.1.0'  # because solrizer is no longer included in Hyrax 3
# gem 'linkeddata',  '<= 3.1.1'  # need to look into latest version of this
# gem 'rdf-rdfa',    '< 3.1.1'   # need to look into latest version of this
# gem 'rdf-vocab',   '<= 3.1.4'  # need to look into latest version of this
# gem 'libxml-ruby', '~> 3.1.0'
gem 'libxml-ruby', '>= 3.1.0'

gem 'dropbox_api' # , '0.1.18' # pin this as it breaks on later versions causing browse everything with dropbox to fail

# gem 'config'

#gem 'devise', '>= 4.7.1'
#gem 'devise-guests', '~> 0.7'
# gem 'devise-guests', '>= 0.7'

# Bundler could not find compatible versions for gem "faraday":
#   In Gemfile:
#     faraday (~> 2)
#
#     hyrax (= 2.9.5) was resolved to 2.9.5, which depends on
#       signet was resolved to 0.12.0, which depends on
#         faraday (~> 0.9)
# gem 'faraday', '~> 1.0'
# NOTE: This is the last minor release in the v0.x series, next release will be 1.0 to match Faraday v1.0 release and from then on only fixes will be applied to v0.14.x!
# gem 'faraday_middleware', '~> 1.0'

#hyrax5 gem 'faraday'

# needed by resque-web
gem 'font-awesome-sass', '>= 6.0'

gem 'mutex_m', '0.2.0'

gem 'deprecation'

# gem 'blacklight-gallery', '~> 4.0'
# gem 'blacklight-gallery', '>= 4.0'

# # gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics'
# # gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', tag: 'v0.0.4'
# gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', branch: 'BLUEDOC-1101-pull-updates-from-dbd-to-irus-analytics-gem-2'
# # gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics'
gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', ref: 'cbffb84ee2db696c8d8a3ca1a0aae7aae37f33fa'
# gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics'
# gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', tag: 'v0.0.4'
# gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', branch: 'BLUEDOC-1101-pull-updates-from-dbd-to-irus-analytics-gem-2'
#gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics'

# Date range support
# gem 'edtf'

# gem 'redis-rails'
# gem 'json', '>= 2.1.0'
# gem 'bolognese', '~> 1.8', '>= 1.8.6'
# gem 'bolognese', '>= 2.0.0'
gem 'bolognese'
# gem 'maremma', '~> 5.0'
# gem 'maremma', git: 'https://github.com/mlibrary/maremma'
# gem 'bolognese', git: 'https://github.com/mlibrary/bolognese'

gem 'public_suffix', '>= 2.0.2', '< 2.1'
# gem 'postrank-uri', '~> 1.0', '>= 1.0.18'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'net-ldap'

# EZID client from Duke
gem 'ezid-client'

# jQuery plugin for drop-in fix binded events problem caused by Turbolinks
# gem 'jquery-turbolinks'

# gem 'willow_sword', git: 'https://github.com/CottageLabs/willow_sword.git', branch: 'develop'

gem 'samvera-persona' #, '0.1.7'
# gem 'samvera-persona', :github => 'samvera-labs/samvera-persona', :branch => 'remove-generator-config'
#     'samvera-persona' adds the use of 'class.module_parent_name'
#hyrax5 - gem 'samvera-persona', '< 0.3.0' # investigate lastest version of this --> it's 0.2.0


##############################################################################
# Use MySQL as the database for Active Record
##############################################################################
# gem 'mysql2'

# Begin security vulnerability mitigation
# bundle update --source gem-name
gem 'activerecord',   '>= 5.2.8.1'
# gem 'addressable',    '>= 2.8.0'
#gem 'addressable',    '>= 2.8.0', '<= 2.8.4'
gem 'addressable', '2.8.1' # a higher version causes issues, namely it throws
gem 'bootstrap-sass', '~> 3.4.1'
#hyrax5 gem 'carrierwave',    '~> 1.3.2'
# gem 'carrierwave',    '>= 1.3.2'
gem 'globalid',       '>= 1.0.1'
gem 'loofah',         '~> 2.19.1'
# gem 'nokogiri',       '>= 1.13.10'
gem 'rack',           '>= 2.2.6.2'
# gem 'rails-html-sanitizer', '>= 1.4.4'
gem 'rubyzip',        '~> 2.0.0'
gem 'sassc',          '>= 2.0.0'
#hyrax5 - gem "sinatra",        '>= 3.0.4'
#hyrax5 - gem 'sprockets',      '~> 3.7.2'
# gem 'sprockets',      '>= 3.7.2'
gem 'websocket-extensions', '>= 0.1.5'
# End security vulnerability mitigation

# gem 'font-awesome-sass', '>= 6.0'

# markdown gems
# gem 'kramdown'
gem 'reverse_markdown'

# gem 'redcarpet', '~> 3.3.4'
# gem 'redcarpet', '~> 3.5.1'
# gem 'redcarpet', '>= 3.5.1'
gem 'redcarpet'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  # gem 'rubocop'
  gem 'rubocop',       '~> 0.49.1'
  gem 'rubocop-rspec', '~> 1.16.0'
end

# gem 'clamav'
gem 'clamav-client'
gem 'down', '~> 4.4'
# gem 'down', '>= 4.4'

gem 'cronex' # https://github.com/alpinweis/cronex
gem 'diffy',         '>= 3.4.1' # https://github.com/samg/diffy
gem 'jira-ruby',     '~> 1.1'
# gem 'okcomputer',    '~> 1.17'
gem 'omniauth',      '>= 1.9.2'
gem 'omniauth-cas'

gem 'resque'
gem 'resque-pool'
gem 'resque-web', '~> 0.0.7', require: 'resque_web'

# https://github.com/resque/resque-scheduler
gem 'resque-scheduler'
gem 'resque-scheduler-web'
# https://github.com/JustinAiken/active_scheduler
gem 'active_scheduler'
gem 'time_difference'

#hyrax5 - gem 'riiif'
# gem 'riiif',         '~> 1.1'
# gem 'riiif', git: 'https://github.com/mlibrary/riiif', tag: '1.4.1-railties-6'

#hyrax5 - gem 'rsolr',         '>= 1.0'

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

# https://github.com/samvera/hydra-role-management
#hyrax5 - TODO: want this - gem 'hydra-role-management'
gem 'hydra-role-management'
# https://github.com/jonahb/akismet
gem 'akismet'

# https://github.com/igorkasyanchuk/new_google_recaptcha
gem 'new_google_recaptcha'

group :development do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  # gem 'web-console', '>= 3.3.0'

  # gem 'equivalent-xml', '~> 0.5'
end

group :development, :test do
  gem 'capybara', '~> 3.29'
  gem 'capybara-screenshot', '~> 1.0'
  gem 'database_cleaner', '~> 1.3'
  gem 'equivalent-xml', '~> 0.5'
  gem 'factory_bot', '~> 4.4'
  gem 'fcrepo_wrapper'
  gem 'mida', '~> 0.3'
  gem 'okcomputer'
  #hyrax5 - gem 'pg', '~> 1.2'

  #hyrax5 - gem 'pry'
  gem 'pry-byebug'
  #hyrax5 - gem 'pry-rails'

  gem 'rspec-activemodel-mocks', '~> 1.0'
  gem 'rspec-its', '~> 1.1'
  gem 'rspec-rails', '~> 6.0'
  gem 'rspec_junit_formatter'
  gem 'selenium-webdriver', '~> 4.4'
  # causes an nil error gem 'i18n-debug'
  # causes an nil error gem 'i18n_yaml_sorter'
  # spec.add_development_dependency 'rails-controller-testing', '~> 1'
  # # the hyrax style guide is based on `bixby`. see `.rubocop.yml`
  # gem 'bixby', '~> 5.0', '>= 5.0.2' # bixby 5 briefly dropped Ruby 2.5
  gem 'shoulda-callback-matchers', '~> 1.1.1'
  gem 'shoulda-matchers', '~> 3.1'

  gem 'rails-controller-testing'

  # gem 'rdf-spec', github: 'ruby-rdf/rdf-spec', branch: 'develop'
  # gem 'rspec-activemodel-mocks'
  # gem 'rspec-its'
  # gem 'rspec-rails'
  gem 'rspec-retry'
  gem 'solr_wrapper',              '>= 4.0.0'
  gem 'webmock'

  # hyrax-orcid begin
  # gem 'shoulda-matchers', '~> 5.0' # update from '~> 3.1' above
  # hyrax-orcid end

end

group :development do
  # Capybara save_and_open_page thingy
  #hyrax5 - gem 'launchy', '~> 2.4.3'
  # Debugger
  # Yay! A Ruby Documentation Tool
  gem 'yard', '>= 0.9.20'
end
