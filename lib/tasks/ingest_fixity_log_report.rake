# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:ingest_fixity_log_report['{"input":"./log/provenance_production.log"}']
  desc 'Report on fixity of ingested files'
  task :ingest_fixity_log_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::IngestFixityLogReport.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_log_task'
  require_relative '../../app/services/deepblue/ingest_fixity_log_reporter'

  class IngestFixityLogReport < AbstractLogTask

    def initialize( options: )
      super( options: options )
      @reporter = IngestFixityLogReporter.new( input: @input, options: options_to_pass )
    end

    def run
      @reporter.report
    end

  end

end
