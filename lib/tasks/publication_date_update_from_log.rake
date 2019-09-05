# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:publication_date_update_from_log
  # bundle exec rake deepblue:publication_date_update_from_log['{"verbose":true}']
  # bundle exec rake deepblue:publication_date_update_from_log['{"input":"./log/provenance_production.log"\,"verbose":true}']
  desc 'Update works publication dates from log'
  task :publication_date_update_from_log, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::PublicationDateUpdateFromLogTask.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_provenance_log_task'
  require_relative '../../app/services/deepblue/publication_date_update_from_log'

  class PublicationDateUpdateFromLogTask < AbstractProvenanceLogTask

    def initialize( options: )
      super( options: options )
      @task = PublicationDateUpdateFromLog.new( input: @input, options: options_to_pass )
    end

    def run
      @task.run
    end

  end

end
