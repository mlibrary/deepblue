# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:log_extract_date_range['{"id":"XYZ12345"\,"input":"./log/provenance_production.log"}']
  desc 'Extract provenance log entries with a given id'
  task :log_extract_id, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::LogExtractId.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_log_task'
  require_relative '../../app/services/deepblue/log_exporter'

  class LogExtractId < AbstractLogTask

    attr_accessor :id

    def initialize( options: )
      super( options: options )
      @exporter = LogExporter.new( input: input, output: output, options: options_to_pass )
      id = task_options_value( key: 'id' )
      filter = IdLogFilter.new( matching_ids: Array( id ) )
      @exporter.filter_and( new_filters: filter )
      return unless DEFAULT_OUTPUT == @output
      @output = @output.sub( 'out', "#{id}.out" )
      @exporter.output = @output
    end

  end

end
