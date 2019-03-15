# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:yaml_populate_from_work[f4752g72m,'{"target_dir":"/deepbluedata-prep"\,"export_files":true\,"mode":"build"}']
  desc 'Yaml populate from work'
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task
  task :yaml_populate_from_work, %i[ id options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromWork.new( id: args[:id], options: args[:options] )
    task.run
  end

  # bundle exec rake deepblue:yaml_populate_from_multiple_works['f4752g72m f4752g72m','{"target_dir":"/deepbluedata-prep"\,"export_files":true\,"mode":"build"}']
  desc 'Yaml populate from multiple works (ids separated by spaces)'
  task :yaml_populate_from_multiple_works, %i[ ids options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromMultipleWorks.new( ids: args[:ids], options: args[:options] )
    task.run
  end

  # bundle exec rake deepblue:yaml_populate_from_all_works['{"target_dir":"/deepbluedata-prep"\,"export_files":false\,"mode":"build"}']
  desc 'Yaml populate from all works'
  task :yaml_populate_from_all_works, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromAllWorks.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require 'open-uri'
  require_relative 'task_helper'
  require_relative 'yaml_populate'

  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  class YamlPopulateFromAllWorks < Deepblue::YamlPopulate

    def initialize( options: )
      super( populate_type: 'work', options: options )
      @export_files = task_options_value( key: 'export_files', default_value: false )
      @ids = []
    end

    def run
      @ids = []
      measurements, total = run_all
      return if @ids.empty?
      report_stats
      report_work( first_id: @ids[0], measurements: measurements, total: total )
    end

  end

  class YamlPopulateFromWork < Deepblue::YamlPopulate

    def initialize( id:, options: )
      super( populate_type: 'work', options: options )
      @id = id
    end

    def run
      measurement = run_one( id: @id )
      report_stats
      report_work( first_id: @id, measurements: [measurement] )
    end

  end

  class YamlPopulateFromMultipleWorks < Deepblue::YamlPopulate

    def initialize( ids:, options: )
      super( populate_type: 'work', options: options )
      @ids = ids.split( ' ' )
    end

    def run
      return if @ids.blank?
      measurements, total = run_multiple( ids: @ids )
      report_stats
      report_work( first_id: @ids[0], measurements: measurements, total: total )
    end

  end

end
