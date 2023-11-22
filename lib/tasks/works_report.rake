# frozen_string_literal: true

require_relative './works_report_task.rb'

namespace :deepblue do

  require_relative '../../app/services/deepblue/works_reporter'

  # bundle exec rake deepblue:works_report
  # bundle exec rake deepblue:works_report['{"verbose":true\,"report_dir":"/deepbluedata-prep/reports"}']
  # bundle exec rake deepblue:works_report['{"verbose":true\,"report_dir":"/deepbluedata-prep/reports"\,"report_file_prefix":"%date%.%time%.%hostname%.works_report"}']
  # bundle exec rake deepblue:works_report['{"verbose":true\,"report_dir":"/deepbluedata-prep/reports"\,"report_file_prefix":"%timestamp%.%hostname%.works_report"}']
  # bundle exec rake deepblue:works_report['{"verbose":true\,"report_dir":"/deepbluedata-prep/reports"\,"report_file_prefix":"%timestamp%.%hostname%.works_report"\,"subscription_service_id":"works_report_job_daily"}']
  desc 'Write report of all works'
  task :works_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    # task = Deepblue::WorksReportTask.new( options: options )
    msg_handler = ::Deepblue::MessageHandler.msg_handler_for( task: true )
    task = ::Deepblue::WorksReporter.new( msg_handler: msg_handler, options: options )
    task.run
  end

end
