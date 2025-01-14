# frozen_string_literal: true

require_relative './report_all_task'

namespace :data_den do

  # bundle exec rake data_den:report_all
  # bundle exec rake data_den:report_all['{"verbose":true}']
  # bundle exec rake data_den:report_all['{"verbose":true\,"report_file":"%date%.data_den_all_work_statuses.csv"}']
  # bundle exec rake data_den:report_all['{"report_dir":"/deepbluedata-prep/reports/"\,"report_file":"%date%.%hostname%.data_den_all_work_statuses.csv"}']
  # bundle exec rake data_den:report_all['{"verbose":true\,"report_dir":"/deepbluedata-prep/reports/"\,"report_file":"%date%.%hostname%.data_den_all_work_statuses.csv"}']
  # bundle exec rake data_den:report_all['{"verbose":true}']
  # bundle exec rake data_den:report_all['{"debug_verbose":true}']
  desc 'Report all DataDen exported files'
  task :report_all, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::ReportAllTask.new( options: args[:options] )
    task.run
  end

end
