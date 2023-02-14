# frozen_string_literal: true

require_relative './works_report_task.rb'

namespace :deepblue do

  require_relative '../../app/services/deepblue/work_impact_reporter'

  # bundle exec rake deepblue:work_impact_report

  # bundle exec rake deepblue:work_impact_report['{"verbose":true\,"report_dir":"./data/reports"}']
  # bundle exec rake deepblue:work_impact_report['{"verbose":true\,"report_dir":"./data/reports"\,"report_file_prefix":"%date%.%time%.%hostname%.work_impact_report"}']
  # bundle exec rake deepblue:work_impact_report['{"verbose":true\,"skip_admin":false\,"report_dir":"./data/reports"\,"report_file_prefix":"%date%.%time%.%hostname%.work_impact_report"}']
  # bundle exec rake deepblue:work_impact_report['{"verbose":true\,"begin_date":"2021-01-01"\,"end_date":"2022-01-01"\,"report_dir":"./data/reports"\,"report_file_prefix":"%date%.%time%.%hostname%.work_impact_report"}']

  # bundle exec rake deepblue:work_impact_report['{"verbose":true\,"report_dir":"/deepbluedata-dataden/download-prep/reports"}']
  # bundle exec rake deepblue:work_impact_report['{"verbose":true\,"report_dir":"/deepbluedata-dataden/download-prep/reports"\,"report_file_prefix":"%date%.%time%.%hostname%.work_impact_report"}']
  # bundle exec rake deepblue:work_impact_report['{"verbose":true\,"report_dir":"/deepbluedata-dataden/download-prep/reports"\,"report_file_prefix":"%timestamp%.%hostname%.work_impact_report"}']
  # bundle exec rake deepblue:work_impact_report['{"verbose":true\,"skip_admin":false\,"report_dir":"/deepbluedata-dataden/download-prep/reports"\,"report_file_prefix":"%timestamp%.%hostname%.work_impact_report"}']
  # bundle exec rake deepblue:work_impact_report['{"verbose":true\,"report_dir":"/deepbluedata-dataden/download-prep/reports"\,"report_file_prefix":"%timestamp%.%hostname%.work_impact_report"\,"subscription_service_id":"work_impact_report_monthly"}']
  desc 'Write impact report for works'
  task :work_impact_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = ::Deepblue::OptionsHelper.parse args[:options]
    msg_handler = ::Deepblue::MessageHandler.msg_handler_for_task( options: options )
    task = ::Deepblue::WorkImpactReporter.new( msg_handler: msg_handler, options: options )
    task.run
  end

end
