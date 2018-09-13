# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:log_extract_date_range['{"input":"./log/provenance_production.log"\,"begin":"2018-09-05 15:00:00"\,"end":""\,"format":"%Y-%m-%d %H:%M:%S"}']
  desc 'Extract provenance log entries in a given date range'
  task :log_extract_date_range, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::LogExtractDateRange.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_log_task'
  require_relative '../../app/services/deepblue/log_exporter'

  class LogExtractDateRange < AbstractLogTask

    DEFAULT_OUTPUT = './log/out.provenance_production.log'

    attr_accessor :begin_timestamp, :end_timestamp, :format_timestamp

    def initialize( options: )
      super( options: options )
      @output = task_options_value( key: 'output', default_value: DEFAULT_OUTPUT )

      @exporter = LogExporter.new( input: input, output: @output, options: options_to_pass )
      @exporter.add_date_range_filter
      return unless DEFAULT_OUTPUT == @output
      filter = @exporter.date_range_filter
      @output = @output.sub( 'out', "#{filter.date_range_label}.out" )
      @exporter.output = @output
    end

    def run
      @exporter.run
      puts "output written to #{@output}" if verbose
    end

  end

end
