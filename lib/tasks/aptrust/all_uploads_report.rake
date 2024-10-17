# frozen_string_literal: true

require_relative './all_uploads_report_task'

namespace :aptrust do

  # bundle exec rake aptrust:all_uploads_report
  desc 'Report all new and existing re-uploads.'
  task :all_uploads_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::AllUploadsReportTask.new( options: args[:options] )
    task.run
  end

end
