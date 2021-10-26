# frozen_string_literal: true

module Deepblue

  require 'open-uri'
  require_relative 'task_helper'
  require_relative 'yaml_populate'

  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  class YamlPopulateFromAllCollections < Deepblue::YamlPopulate

    attr_accessor :ids

    def initialize( options:, msg_queue: nil  )
      super( populate_type: 'collection', options: options, msg_queue: msg_queue )
      @export_files = task_options_value( key: 'export_files', default_value: false )
      @ids = []
    end

    def run
      measurements, total = run_all
      return if ids.empty?
      report_stats
      report_collection( first_id: ids[0], measurements: measurements, total: total )
    end

  end

  class YamlPopulateFromCollection < Deepblue::YamlPopulate

    def initialize( id:, options:, msg_queue: nil )
      super( populate_type: 'collection', options: options, msg_queue: msg_queue )
      @id = id
    end

    def run
      measurement = run_one( id: @id )
      report_stats
      report_collection( first_id: @id, measurements: [measurement] )
    end

  end

  class YamlPopulateFromMultipleCollections < Deepblue::YamlPopulate

    def initialize( ids:, options:, msg_queue: nil )
      super( populate_type: 'collection', options: options, msg_queue: msg_queue )
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
