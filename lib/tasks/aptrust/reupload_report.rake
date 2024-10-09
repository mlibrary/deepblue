# frozen_string_literal: true

require_relative './reupload_report_task'

namespace :aptrust do

  # bundle exec rake aptrust:reupload_report
  desc 'Report APTrust existing reuploads.'
  task :reupload_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::ReuploadReportTask.new( options: args[:options] )
    task.run
  end

end
