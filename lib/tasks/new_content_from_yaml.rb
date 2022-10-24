# frozen_string_literal: true

module Deepblue

  require 'open-uri'
  require 'tasks/abstract_task'
  require 'tasks/task_helper'
  require 'tasks/new_content_service'
  require_relative '../append_content_service'
  require_relative '../build_content_service'
  require_relative '../update_content_service'
  require 'benchmark'
  include Benchmark

  class NewContentFromYaml < AbstractTask

    DEFAULT_SOURCE_DIR = '/deepbluedata-prep' unless const_defined? :DEFAULT_SOURCE_DIR
    DEFAULT_INGESTER = nil unless const_defined? :DEFAULT_INGESTER
    DEFAULT_MODE = "populate" unless const_defined? :DEFAULT_MODE
    DEFAULT_PREFIX = "" unless const_defined? :DEFAULT_PREFIX
    DEFAULT_POSTFIX = "" unless const_defined? :DEFAULT_POSTFIX

    def initialize( base_file_names:, options: )
      super( options: options )
      @test = false
      @base_file_names = base_file_names.split( ' ' )
      @ingester = task_options_value( key: 'ingester', default_value: DEFAULT_INGESTER )
      @mode = task_options_value( key: 'mode', default_value: DEFAULT_MODE )
      @prefix = task_options_value( key: 'prefix', default_value: DEFAULT_PREFIX )
      @postfix = task_options_value( key: 'postfix', default_value: DEFAULT_POSTFIX )
      @source_dir = Pathname.new task_options_value( key: 'source_dir', default_value: DEFAULT_SOURCE_DIR )
    end

    def expand_file_names( base_file_names )
      file_names = []
      Array( base_file_names ).each do |base_file_name|
        file_name = @source_dir.join "#{@prefix}#{base_file_name}#{@postfix}.yml"
        file_names << file_name.to_s
      end
      file_names
    end

    # def report_collection( first_id:, measurements:, total: nil )
    #   # TaskHelper.benchmark_report( label: 'coll id', first_id: first_id, measurements: measurements, total: total )
    # end
    #
    # def report_users( first_id:, measurements:, total: nil )
    #   # TaskHelper.benchmark_report( label: 'users', first_id: first_id, measurements: measurements, total: total )
    # end

    def report_stats

    end

    def report_work( first_id:, measurements:, total: nil )
      TaskHelper.benchmark_report( label: first_id,
                                   first_id: first_id,
                                   measurements: measurements,
                                   total: total,
                                   msg_handler: msg_handler )
    end

    def run
      return if @base_file_names.blank?
      file_names = expand_file_names(@base_file_names )
      measurements, total = run_multiple( file_names: file_names )
      report_stats
      first_id = File.basename( file_names[0], ".*" )
      report_work( first_id: first_id, measurements: measurements, total: total )
    end

    def run_multiple( file_names: )
      total = nil
      measurements = []
      file_names.each do |file_name|
        first_label = File.basename( file_name, ".*" )
        subtotal = case @mode
                   when NewContentService::MODE_APPEND
                     append_one( file_name: file_name, first_label: first_label )
                   when NewContentService::MODE_BUILD
                     build_one( file_name: file_name, first_label: first_label )
                   when NewContentService::MODE_MIGRATE
                     migrate_one( file_name: file_name, first_label: first_label )
                   when NewContentService::MODE_UPDATE
                     update_one( file_name: file_name, first_label: first_label )
                   else
                     puts "Don't know how to #{@mode} file '#{file_name}"
                     0
                   end
        measurements << subtotal
        if total.nil?
          total = subtotal
        else
          total += subtotal
        end
      end
      return measurements, total
    end

    def append_one( file_name:, first_label: )
      measurement = Benchmark.measure( file_name ) do
        puts "Appending content using yaml file '#{file_name}'"
        AppendContentService.call( path_to_yaml_file: file_name,
                                   ingester: @ingester,
                                   first_label: first_label,
                                   options: @options ) unless @test
      end
      return measurement
    end

    def build_one( file_name:, first_label: )
      measurement = Benchmark.measure( file_name ) do
        puts "Building content using yaml file '#{file_name}'"
        BuildContentService.call( path_to_yaml_file: file_name,
                                  ingester: @ingester,
                                  first_label: first_label,
                                  options: @options ) unless @test
      end
      return measurement
    end

    def migrate_one( file_name:, first_label: )
      measurement = Benchmark.measure( file_name ) do
        puts "Migrating content using yaml file '#{file_name}'"
        BuildContentService.call( path_to_yaml_file: file_name,
                                  mode: MODE_MIGRATE,
                                  ingester: @ingester,
                                  first_label: first_label,
                                  options: @options ) unless @test
      end
      return measurement
    end

    def update_one( file_name:, first_label: )
      measurement = Benchmark.measure( file_name ) do
        puts "Updating content using yaml file '#{file_name}'"
        UpdateContentService.call( path_to_yaml_file: file_name,
                                   ingester: @ingester,
                                   first_label: first_label,
                                   options: @options ) unless @test
      end
      return measurement
    end

  end

end
