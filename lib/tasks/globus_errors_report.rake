# frozen_string_literal: true

require_relative './globus_errors_report'

namespace :deepblue do

  # bundle exec rake deepblue:globus_errors_report
  # bundle exec rake deepblue:globus_errors_report['{"verbose":true}']
  desc 'Report on Globus errors'
  task :globus_errors_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::GlobusErrorsReport.new( options: args[:options] )
    task.run
  end

end
