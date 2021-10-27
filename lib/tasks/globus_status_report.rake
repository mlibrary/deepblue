# frozen_string_literal: true

require_relative './globus_status_report'

namespace :deepblue do

  # bundle exec rake deepblue:globus_status_report
  # bundle exec rake deepblue:globus_status_report['{"verbose":true\,"quiet":false}']
  # bundle exec rake deepblue:globus_status_report['{"quiet":true}']
  # bundle exec rake deepblue:globus_status_report['{"quiet":false}']
  # bundle exec rake deepblue:globus_status_report['{"quiet":false\,"report_dir":"/deepbluedata-prep/reports"}']
  # bundle exec rake deepblue:globus_status_report['{"quiet":false\,"report_dir":"/deepbluedata-prep/reports"\,"report_file_prefix":"%date%.%time%.%hostname%.works_report"}']
  # bundle exec rake deepblue:globus_status_report['{"quiet":false\,"report_dir":"/deepbluedata-prep/reports"\,"report_file_prefix":"%timestamp%.%hostname%.works_report"}']
  desc 'Report on Globus errors'
  task :globus_status_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::GlobusStatusReport.new( options: args[:options] )
    task.run
  end

end
