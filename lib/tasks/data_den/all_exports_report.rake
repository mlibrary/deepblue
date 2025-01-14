# frozen_string_literal: true

require_relative './all_exports_report_task'

namespace :data_den do

  # bundle exec rake data_den:all_exports_report
  desc 'Report all new and modified re-exports.'
  task :all_exports_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::AllExportsReportTask.new( options: args[:options] )
    task.run
  end

end
