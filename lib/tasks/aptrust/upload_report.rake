# frozen_string_literal: true

require_relative './upload_report_task'

namespace :aptrust do

  # bundle exec rake aptrust:upload_report
  desc 'Report APTrust uploads remaining.'
  task :upload_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::UploadReportTask.new( options: args[:options] )
    task.run
  end

end
