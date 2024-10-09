# frozen_string_literal: true

require_relative './cleanup_report_task'

namespace :aptrust do

  # bundle exec rake aptrust:cleanup_report
  desc 'Cleanup APTrust work files weekly.'
  task :cleanup_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::CleanupReportTask.new( options: args[:options] )
    task.run
  end

end
