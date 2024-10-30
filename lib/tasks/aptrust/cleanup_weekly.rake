# frozen_string_literal: true

require_relative './cleanup_weekly_task'

namespace :aptrust do

  # bundle exec rake aptrust:cleanup_weekly
  desc 'Cleanup APTrust work one week or more old.'
  task :cleanup_weekly, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::CleanupWeeklyTask.new( options: args[:options] )
    task.run
  end

end
