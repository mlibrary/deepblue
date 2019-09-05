# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:publication_log_report['{"format":"YYYMMDD"\,"begin":"20190101"\,"end":"20200101"}']
  # bundle exec rake deepblue:publication_log_report['{"input":"./log/provenance_development.log"\,"format":"YYYMMDD"\,"begin":"20190101"\,"end":"20200101"}']
  desc 'Report on published works using log'
  task :publication_log_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::PublicationLogReport.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_provenance_log_task'
  require_relative '../../app/services/deepblue/publication_log_reporter'

  class PublicationLogReport < AbstractProvenanceLogTask

    def initialize( options: )
      super( options: options )
      @reporter = PublicationLogReporter.new( input: @input, options: options_to_pass )
    end

    def run
      @reporter.report
    end

  end

end
