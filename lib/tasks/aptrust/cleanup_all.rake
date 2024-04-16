# frozen_string_literal: true

require_relative './cleanup_all_task'

namespace :aptrust do

  # bundle exec rake aptrust:cleanup_all
  # bundle exec rake aptrust:cleanup_all['{"verbose":true\,"test_mode":true}']
  # bundle exec rake aptrust:cleanup_all['{"verbose":true}']
  # bundle exec rake aptrust:cleanup_all['{"verbose":true\,"test_mode":true\,"date_end":"2024/04/11 00:00:00"}']
  desc 'Cleanup APTrust all upload files'
  task :cleanup_all, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::CleanupAllTask.new( options: args[:options] )
    task.run
  end

end
