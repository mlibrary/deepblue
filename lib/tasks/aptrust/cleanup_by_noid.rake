# frozen_string_literal: true

require_relative './cleanup_by_noid_task'

namespace :aptrust do

  # bundle exec rake aptrust:cleanup_by_noid
  # bundle exec rake aptrust:cleanup_by_noid['{"noids":"noid1"}']
  # bundle exec rake aptrust:cleanup_by_noid['{"noids":"noid1"\,"sleep_secs":30\,"debug_verbose":true}']
  # bundle exec rake aptrust:cleanup_by_noid['{"noids":" noid1 noid2"\,"verbose":true}']
  desc 'Cleanup APTrust upload files by list of noids'
  task :cleanup_by_noid, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::CleanupByNoidTask.new( options: args[:options] )
    task.run
  end

end
