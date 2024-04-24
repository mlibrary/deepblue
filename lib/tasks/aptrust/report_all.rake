# frozen_string_literal: true

require_relative './report_all_task'

namespace :aptrust do

  # bundle exec rake aptrust:report_all
  # bundle exec rake aptrust:report_all['{"verbose":true}']
  # bundle exec rake aptrust:report_all['{"verbose":true\,"report_file":"%date%.aptrust_all_work_statuses.csv"}']
  # bundle exec rake aptrust:report_all['{"verbose":true\,"report_dir":"/deepbluedata-prep/reports/","report_file":"%date%.%hostname%.aptrust_all_work_statuses.csv"}}']
  desc 'Report all APTrust uploaded files'
  task :report_all, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::ReportAllTask.new( options: args[:options] )
    task.run
  end

end
