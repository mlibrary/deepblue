# frozen_string_literal: true

require 'tasks/report_task'
require 'tasks/export_log_files_task'

namespace :deepblue do

  # bundle exec rake deepblue:export_log_files
  # bundle exec rake deepblue:export_log_files['{"verbose":true}']
  desc 'Run report'
  task :run_report, %i[ path_to_template options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = ::Deepblue::ExportLogFilesTask.new( options: options )
    task.run
  end

end
