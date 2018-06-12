# frozen_string_literal: true

require 'yaml'
require_relative '../build_content_service'
require_relative '../append_content_service'

namespace :umrdr do

  desc "Populate app with users,collections,works,files."
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task
  task :populate, [:path_to_config] => :environment do |_t, args|
    ENV["RAILS_ENV"] ||= "development"

    # See: Rake::TaskArguments for args class
    puts "args=#{args}"
    # puts "args=#{JSON.pretty_print args.to_hash.as_json}"

    args.one? ? config_setup( args[:path_to_config], args ) : demo_setup

    puts "Done."
  end

  desc "Append files to existing collections."
  task :append, [:path_to_config] => :environment do |_t, args|
    ENV["RAILS_ENV"] ||= "development"

    args.one? ? config_setup_for_append( args[:path_to_config], args ) : demo_setup

    puts "Done."
  end

end

def config_setup( path_to_config, args )
  unless File.exist? path_to_config
    puts "bad path to config"
    return
  end
  BuildContentService.call( path_to_config, args )
end

def config_setup_for_append( path_to_config, args )
  unless File.exist? path_to_config
    puts "bad path to config"
    return
  end
  AppendContentService.call( path_to_config, args )
end

def demo_setup
  # Create user if doesn't already exist
  email = 'demouser@example.com'
  user = User.find_by( email: email ) || create_user( email )
  puts "user: #{user.user_key}"

  # Create work and attribute to user if they don't already have at least one.
  if DataSet.where(Solrizer.solr_name('depositor', :symbol) => user.user_key).count < 1 # rubocop:disable Style/GuardClause
    create_demo_work(user)
    puts "demo work created."
  end
end

def create_user(email = 'demouser@example.com')
  pwd = "password"
  User.create!(email: email, password: pwd, password_confirmation: pwd)
end

def create_demo_work(user)
  # It did not like attribute tag - need to find
  gw = DataSet.new( title: ['Demowork'], owner: user.user_key, description: ["A demonstration work for populating the repo."])
  gw.apply_depositor_metadata(user.user_key)
  gw.visibility = "open"
  gw.save
end
