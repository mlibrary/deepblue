# frozen_string_literal: true

require_relative './globus_errors_report'

namespace :deepblue do

  # bundle exec rake deepblue:globus_errors_report
  # bundle exec rake deepblue:globus_errors_report['{"verbose":true\,"quiet":false}']
  # bundle exec rake deepblue:globus_errors_report['{"quiet":true}']
  # bundle exec rake deepblue:globus_errors_report['{"quiet":false\,"report_dir":"."\,"report_file_prefix":"%timestamp%.%hostname%.globus_errors_report"}']
  # bundle exec rake deepblue:globus_errors_report['{"quiet":false}']
  # bundle exec rake deepblue:globus_errors_report['{"quiet":false\,"report_dir":"/deepbluedata-prep/reports"}']
  # bundle exec rake deepblue:globus_errors_report['{"quiet":false\,"report_dir":"/deepbluedata-prep/reports"\,"report_file_prefix":"%date%.%time%.%hostname%.globus_errors_report"}']
  # bundle exec rake deepblue:globus_errors_report['{"quiet":false\,"report_dir":"/deepbluedata-prep/reports"\,"report_file_prefix":"%timestamp%.%hostname%.globus_errors_report"}']
  desc 'Report on Globus errors'
  task :globus_errors_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    msg_handler = ::Deepblue::MessageHandler.msg_handler_for( task: true )
    task = Deepblue::GlobusErrorsReport.new( msg_handler: msg_handler, options: args[:options] )
    task.run
  end

end
