# frozen_string_literal: true

require 'yaml'
require_relative '../append_content_service'
require_relative '../build_content_service'
require_relative '../ingest_users_service'

namespace :umrdr do

  # See: Rake::TaskArguments for args class
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task

  # bundle exec rake umrdr:append[/deepbluedata-prep/w_9019s2443_populate.yml]
  # bundle exec rake umrdr:append[/deepbluedata-prep/w_9019s2443_populate.yml,ingester@umich.edu]
  desc "Append files to existing collections."
  task :append, %i[ path_to_yaml_file ingester ] => :environment do |_t, args|
    ENV["RAILS_ENV"] ||= "development"
    args.with_defaults( ingester: '' )
    content_append( path_to_yaml_file: args[:path_to_yaml_file], ingester: args[:ingester], args: args )
    puts "Done."
  end

  # bundle exec rake umrdr:build[/deepbluedata-prep/w_9019s2443_populate.yml]
  # bundle exec rake umrdr:build[/deepbluedata-prep/w_9019s2443_populate.yml,ingester@umich.edu]
  desc "Build app with  collections, works, and files."
  task :build, %i[ path_to_yaml_file ingester ] => :environment do |_t, args|
    ENV["RAILS_ENV"] ||= "development"
    args.with_defaults( ingester: '' )
    content_build( path_to_yaml_file: args[:path_to_yaml_file], ingester: args[:ingester], args: args )
    puts "Done."
  end

  # bundle exec rake umrdr:demo_content
  desc "Set up demo content"
  task demo_content: :environment do |_t, _args|
    ENV["RAILS_ENV"] ||= "development"
    demo_content
    puts "Done."
  end

  # bundle exec rake umrdr:migrate[/deepbluedata-prep/w_9019s2443_populate.yml]
  # bundle exec rake umrdr:migrate[/deepbluedata-prep/w_9019s2443_populate.yml,ingester@umich.edu]
  desc "Migrate collections and works."
  task :migrate, %i[ path_to_yaml_file ingester ] => :environment do |_t, args|
    ENV["RAILS_ENV"] ||= "development"
    args.with_defaults( ingester: '' )
    content_migrate( path_to_yaml_file: args[:path_to_yaml_file], ingester: args[:ingester], args: args )
    puts "Done."
  end

  # bundle exec rake umrdr:populate[/deepbluedata-prep/w_9019s2443_populate.yml]
  # bundle exec rake umrdr:populate[/deepbluedata-prep/w_9019s2443_populate.yml,ingester@umich.edu]
  desc "Populate app with collections, works, and files."
  task :populate, %i[ path_to_yaml_file ingester ] => :environment do |_t, args|
    ENV["RAILS_ENV"] ||= "development"
    # See: Rake::TaskArguments for args class
    # puts "args=#{args}"
    # puts "args=#{JSON.pretty_print args.to_hash.as_json}"
    args.with_defaults( ingester: '' )
    content_populate( path_to_yaml_file: args[:path_to_yaml_file], ingester: args[:ingester], args: args )
    puts "Done."
  end

  # bundle exec rake umrdr:populate_users[/deepbluedata-prep/users_build.yml,'{"verbose":true}']
  desc "Populate users."
  task :populate_users, %i[ path_to_yaml_file ingester options ] => :environment do |_t, args|
    ENV["RAILS_ENV"] ||= "development"
    args.with_defaults( ingester: '', options: {} )
    content_populate_users( path_to_yaml_file: args[:path_to_yaml_file],
                            ingester: args[:ingester],
                            options: args[:options],
                            args: args )
    puts "Done."
  end

end

def content_append( path_to_yaml_file:, ingester: nil, options: {}, args: )
  return unless valid_path_to_yaml_file? path_to_yaml_file
  AppendContentService.call( path_to_yaml_file: path_to_yaml_file,
                             ingester: ingester,
                             mode: Deepblue::NewContentService::MODE_APPEND,
                             options: options,
                             args: args )
end

def content_build( path_to_yaml_file:, ingester: nil, options: {}, args: )
  return unless valid_path_to_yaml_file? path_to_yaml_file
  BuildContentService.call( path_to_yaml_file: path_to_yaml_file,
                            ingester: ingester,
                            mode: Deepblue::NewContentService::MODE_BUILD,
                            options: options,
                            args: args )
end

def content_migrate( path_to_yaml_file:, ingester: nil, options: {}, args: )
  return unless valid_path_to_yaml_file? path_to_yaml_file
  BuildContentService.call( path_to_yaml_file: path_to_yaml_file,
                            ingester: ingester,
                            mode: Deepblue::NewContentService::MODE_MIGRATE,
                            options: options,
                            args: args )
end

def content_populate( path_to_yaml_file:, ingester: nil, options: {}, args: )
  return unless valid_path_to_yaml_file? path_to_yaml_file
  # mode determined in yaml file, defaulting to append mode
  BuildContentService.call( path_to_yaml_file: path_to_yaml_file,
                            ingester: ingester,
                            options: options,
                            args: args )
end

def content_populate_users( path_to_yaml_file:, ingester: nil, options:, args: )
  return unless valid_path_to_yaml_file? path_to_yaml_file
  IngestUsersService.call( path_to_yaml_file: path_to_yaml_file,
                           ingester: ingester,
                           options: options,
                           args: args )
end

def create_user( email: 'demouser@example.com' )
  pwd = "password"
  User.create!( email: email, password: pwd, password_confirmation: pwd )
end

def create_demo_work( user: )
  # It did not like attribute tag - need to find
  gw = DataSet.new( title: ['Demowork'], owner: user.user_key, description: ["A demonstration work for populating the repo."])
  gw.apply_depositor_metadata(user.user_key)
  gw.visibility = "open"
  gw.save
end

def demo_content
  # Create user if user doesn't already exist
  email = 'demouser@example.com'
  user = User.find_by( email: email ) || create_user( email: email )
  puts "user: #{user.user_key}"

  # Create work and attribute to user if they don't already have at least one.
  return unless DataSet.where( Solrizer.solr_name('depositor', :symbol) => user.user_key ).count < 1
  create_demo_work( user: user )
  puts "demo work created."
end

def valid_path_to_yaml_file?( path_to_yaml_file )
  return true if File.exist? path_to_yaml_file
  puts "Bad path to config: #{path_to_yaml_file}"
  return false
end
