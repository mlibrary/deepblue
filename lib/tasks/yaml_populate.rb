# frozen_string_literal: true

require 'open-uri'

module Deepblue

  require 'tasks/abstract_task'
  require_relative 'task_helper'
  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  class YamlPopulate < AbstractTask

    DEFAULT_EXPORT_FILES = true
    DEFAULT_MODE = 'build'
    DEFAULT_TARGET_DIR = '/deepbluedata-prep'

    attr_accessor :populate_ids
    attr_accessor :populate_type
    attr_accessor :populate_stats

    def initialize( populate_type:, options: )
      super( options: options )
      @populate_type = populate_type
      @target_dir = task_options_value( key: 'target_dir', default_value: DEFAULT_TARGET_DIR )
      @export_files = task_options_value( key: 'export_files', default_value: DEFAULT_EXPORT_FILES )
      @mode = task_options_value( key: 'mode', default_value: DEFAULT_MODE )
      @populate_ids = []
      @populate_stats = []
    end

    def report_collection( first_id:, measurements:, total: nil )
      TaskHelper.benchmark_report( label: 'coll id', first_id: first_id, measurements: measurements, total: total )
    end

    def report_users( first_id:, measurements:, total: nil )
      TaskHelper.benchmark_report( label: 'users', first_id: first_id, measurements: measurements, total: total )
    end

    def report_stats
      puts
      if @populate_ids.empty?
        puts "users: #{stats[:total_users_exported]}"
        return
      end
      index = 0
      total_collections = 0
      total_works = 0
      total_file_sets = 0
      total_file_sets_size = 0
      populate_stats.each do |stats|
        collections = stats[:total_collections_exported]
        works = stats[:total_works_exported]
        file_sets = stats[:total_file_sets_exported]
        size_readable = stats[:total_file_sets_size_readable_exported]
        file_sets_size = stats[:total_file_sets_size_exported]
        id = @populate_ids[index]
        puts "#{id} collections: #{collections} works: #{works} file_sets: #{file_sets} size: #{size_readable}"
        total_collections += collections
        total_works += works
        total_file_sets = file_sets
        total_file_sets_size = file_sets_size
        index += 1
      end
      if @populate_ids.size > 1
        puts "totals collections: #{total_collections} works: #{total_works} file_sets: #{total_file_sets} size: #{TaskHelper.human_readable_size( total_file_sets_size )}"
      end
      puts
    end

    def report_work( first_id:, measurements:, total: nil )
      TaskHelper.benchmark_report( label: 'work id', first_id: first_id, measurements: measurements, total: total )
    end

    def run_multiple( ids: )
      total = nil
      measurements = []
      ids.each do |id|
        subtotal = run_one( id: id )
        measurements << subtotal
        if total.nil?
          total = subtotal
        else
          total += subtotal
        end
      end
      return measurements, total
    end

    def run_one( id: )
      measurement = Benchmark.measure( id ) do
        if 'work' == @populate_type
          yaml_populate_work( id: id )
        else
          yaml_populate_collection( id: id )
        end
      end
      return measurement
    end

    def yaml_populate_collection( id: )
      puts "Exporting collection #{id} to '#{@target_dir}' with export files flag set to #{@export_files} and mode #{@mode}"
      service = YamlPopulateService.new( mode: @mode )
      service.yaml_populate_collection( collection: id, dir: @target_dir, export_files: @export_files )
      @populate_ids << id
      @populate_stats << service.yaml_populate_stats
      # Deepblue::MetadataHelper.yaml_populate_collection( collection: id,
      #                                                    dir: @target_dir,
      #                                                    export_files: @export_files,
      #                                                    mode: @mode )
    end

    def yaml_populate_work( id: )
      puts "Exporting work #{id} to '#{@target_dir}' with export files flag set to #{@export_files} and mode #{@mode}"
      service = YamlPopulateService.new( mode: @mode )
      service.yaml_populate_work( curation_concern: id, dir: @target_dir, export_files: @export_files )
      @populate_ids << id
      @populate_stats << service.yaml_populate_stats
      # Deepblue::MetadataHelper.yaml_populate_work( curation_concern: id,
      #                                              dir: @target_dir,
      #                                              export_files: @export_files,
      #                                              mode: @mode )
    end

  end

end
