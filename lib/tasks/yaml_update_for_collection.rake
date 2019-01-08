# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:yaml_update_for_collections['f4752g72m f4752g72m','{"source_dir":"/deepbluedata-prep"\,"ingester":"ingester@umich.edu"}']
  desc 'Yaml update for collections (ids separated by spaces)'
  task :yaml_update_for_collections, %i[ ids options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlUpdateForCollections.new( ids: args[:ids], options: args[:options] )
    task.run
  end

end

module Deepblue

  require 'open-uri'
  require_relative 'task_helper'
  require_relative 'yaml_update'
  require 'benchmark'
  include Benchmark

  class YamlUpdateForCollections < Deepblue::YamlUpdate

    def initialize( ids:, options: )
      super( update_type: 'collection', options: options )
      @ids = ids.split( ' ' )
    end

    def run
      return if @ids.blank?
      measurements, total = run_multiple( ids: @ids )
      report_stats
      report_collection( first_id: @ids[0], measurements: measurements, total: total )
    end

  end

end
