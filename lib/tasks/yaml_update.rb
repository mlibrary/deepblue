# frozen_string_literal: true

require 'open-uri'

module Deepblue

  require 'tasks/abstract_task'
  require_relative 'task_helper'
  require_relative '../update_content_service'
  require 'benchmark'
  include Benchmark

  class YamlUpdate < AbstractTask

    DEFAULT_SOURCE_DIR = '/deepbluedata-prep'
    DEFAULT_INGESTER = nil

    def initialize( update_type:, options: )
      super( options: options )
      @update_type = update_type
      @ingester = task_options_value( key: 'ingester', default_value: DEFAULT_INGESTER )
      @source_dir = task_options_value( key: 'source_dir', default_value: DEFAULT_SOURCE_DIR )
    end

    def report_collection( first_id:, measurements:, total: nil )
      # TaskHelper.benchmark_report( label: 'coll id', first_id: first_id, measurements: measurements, total: total )
    end

    def report_users( first_id:, measurements:, total: nil )
      # TaskHelper.benchmark_report( label: 'users', first_id: first_id, measurements: measurements, total: total )
    end

    def report_stats

    end

    def report_work( first_id:, measurements:, total: nil )
      # TaskHelper.benchmark_report( label: 'work id', first_id: first_id, measurements: measurements, total: total )
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
        if 'work' == @update_type
          yaml_update_work( id: id )
        else
          yaml_update_collection( id: id )
        end
      end
      return measurement
    end

    def yaml_update_collection( id: )
      path_to_yaml_file = "#{@source_dir}/c_#{id}_populate.yml"
      puts "Updating work #{id}  using yaml file '#{path_to_yaml_file}'"
      UpdateContentService.call( path_to_yaml_file: path_to_yaml_file, ingester: @ingester, options: @options )
    end

    def yaml_update_work( id: )
      path_to_yaml_file = "#{@source_dir}/w_#{id}_populate.yml"
      puts "Updating work #{id}  using yaml file '#{path_to_yaml_file}'"
      UpdateContentService.call( path_to_yaml_file: path_to_yaml_file, ingester: @ingester, options: @options )
    end

  end

end
