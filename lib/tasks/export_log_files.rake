# frozen_string_literal: true

require_relative '../../app/tasks/deepblue/report_task'
require 'tasks/export_log_files_task'

namespace :deepblue do

  # bundle exec rake deepblue:export_log_files
  # bundle exec rake deepblue:export_log_files['{"verbose":true}']
  desc 'Export log files to prep'
  task :export_log_files, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = ::Deepblue::ExportLogFilesTask.new( options: options )
    task.run
  end

end
