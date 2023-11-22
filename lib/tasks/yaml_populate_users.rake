# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:yaml_populate_users['{"target_dir":"/deepbluedata-prep","mode":"migrate"}']
  desc 'Yaml populate users'
  task :yaml_populate_users, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateUsers.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require_relative '../../app/tasks/deepblue/yaml_populate'

  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  class YamlPopulateUsers < YamlPopulate

    def initialize( options: )
      super( populate_type: 'users', options: options )
    end

    def run
      measurement = run_users
      report_stats
      report_users( first_id: 'users', measurements: [measurement] )
    end

    def run_users
      measurement = Benchmark.measure( 'users' ) do
        yaml_populate_users
      end
      return measurement
    end

    def yaml_populate_users
      puts "Exporting users to '#{@target_dir}' with mode #{@mode}"
      service = YamlPopulateService.new( mode: @mode )
      service.yaml_populate_users( dir: @target_dir )
      @populate_stats << service.yaml_populate_stats
      # Deepblue::MetadataHelper.yaml_populate_users( dir: @target_dir, mode: @mode )
    end

  end

end
