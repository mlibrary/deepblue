# frozen_string_literal: true

require 'tasks/report_task'

namespace :deepblue do

  # bundle exec rake deepblue:run_report[/path/to/template]
  desc 'Run report'
  task :run_report, %i[ path_to_template options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::ReportTask.new( report_definitions_file: args[:path_to_template], options: options )
    task.run
  end

end
