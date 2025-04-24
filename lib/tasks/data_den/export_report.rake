# frozen_string_literal: true

require_relative './export_report_task'

namespace :data_den do

  # bundle exec rake data_den:export_report
  desc 'Report DataDen extracts remaining.'
  task :export_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::ExportReportTask.new( options: args[:options] )
    task.run
  end

end
