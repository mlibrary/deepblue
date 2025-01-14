# frozen_string_literal: true

require_relative './reexport_report_task'

namespace :data_den do

  # bundle exec rake data_den:reexport_report
  desc 'Report APTrust existing reexports.'
  task :reexport_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::ReexportReportTask.new( options: args[:options] )
    task.run
  end

end
