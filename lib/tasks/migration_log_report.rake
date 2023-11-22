# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:migration_log_report['{"input":"./log/provenance_production.log"}']
  desc 'Report on migration'
  task :migration_log_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::MigrationLogReport.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_log_task'
  require_relative '../../app/services/deepblue/migration_log_reporter'

  class MigrationLogReport < AbstractLogTask

    def initialize( options: )
      super( options: options )
      @reporter = MigrationLogReporter.new( input: @input, options: options_to_pass )
    end

    def run
      @reporter.report
    end

  end

end
