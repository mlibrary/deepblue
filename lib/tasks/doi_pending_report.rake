# frozen_string_literal: true

require_relative './doi_pending_report_task'

namespace :deepblue do

  # bundle exec rake deepblue:doi_pending_report
  # bundle exec rake deepblue:doi_pending_report['{"verbose":true\,"quiet":false}']
  # bundle exec rake deepblue:doi_pending_report['{"quiet":true}']
  # bundle exec rake deepblue:doi_pending_report['{"quiet":false\,"report_dir":"."\,"report_file_prefix":"%timestamp%.%hostname%.doi_pending_report"}']
  # bundle exec rake deepblue:doi_pending_report['{"quiet":false}']
  # bundle exec rake deepblue:doi_pending_report['{"quiet":false\,"report_dir":"/deepbluedata-prep/reports"}']
  # bundle exec rake deepblue:doi_pending_report['{"quiet":false\,"report_dir":"/deepbluedata-prep/reports"\,"report_file_prefix":"%date%.%time%.%hostname%.doi_pending_report"}']
  # bundle exec rake deepblue:doi_pending_report['{"quiet":false\,"report_dir":"/deepbluedata-prep/reports"\,"report_file_prefix":"%timestamp%.%hostname%.doi_pending_report"}']
  desc 'Report on pending DOI'
  task :doi_pending_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Deepblue::DoiPendingReportTask.new( options: args[:options] )
    task.run
  end

end
