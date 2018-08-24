# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:yaml_populate_from_collection[nk322d32h,/deepbluedata-prep,true]
  desc 'Yaml populate from collection'
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task
  task :yaml_populate_from_collection, %i[ id options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromCollection.new( id: args[:id], options: args[:options] )
    task.run
  end

  # bundle exec rake umrdr:yaml_populate_from_multiple_collections['f4752g72m f4752g72m',/deepbluedata-prep,true]
  desc 'Yaml populate from multiple collections (ids separated by spaces)'
  task :yaml_populate_from_multiple_collections, %i[ ids options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromMultipleCollections.new( ids: args[:ids], options: args[:options] )
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

  class YamlPopulateFromCollection < Deepblue::YamlPopulate

    def initialize( id:, options: )
      super( populate_type: 'collection', options: options )
      @id = id
    end

    def run
      measurement = run_one( id: @id )
      report_collection( first_id: @id, measurements: [measurement] )
    end

  end

  class YamlPopulateFromMultipleCollections < Deepblue::YamlPopulate

    def initialize( ids:, options: )
      super( populate_type: 'collection', options: options )
      @ids = ids.split( ' ' )
    end

    def run
      return if @ids.blank?
      measurements, total = run_multiple( ids: @ids )
      report_collection( first_id: @ids[0], measurements: measurements, total: total )
    end

  end

end
