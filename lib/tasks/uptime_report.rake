# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:uptime_report['{"verbose":true}']
  # bundle exec rake deepblue:uptime_report['{"sleep":10}']
  desc 'Report on fixity of ingested files'
  task :uptime_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::UptimeReport.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_task'
  require_relative '../../app/services/deepblue/uptime_service'

  class UptimeReport < AbstractTask

    attr_accessor :options

    def initialize( options: )
      super( options: options )
    end

    def run
      sleep_value = @options["sleep"]
      puts "sleep_value=#{sleep_value} & class=#{sleep_value.class.name}"
      if sleep_value.present?
        puts "sleeping for #{sleep_value.to_i} seconds"
        sleep sleep_value.to_i
      end
      puts "load_timestamp: #{UptimeService.load_timestamp}"
      puts "program_name: #{UptimeService.program_name}"
      puts "uptime: #{UptimeService.uptime.round(2)} seconds"
      uptime_vs_rails = UptimeService.uptime_vs_rails
      puts "rails is not running" if uptime_vs_rails.nil?
      return if uptime_vs_rails.nil?
      puts "uptime_vs_rails: #{-uptime_vs_rails.round(2)} seconds after rails started" if uptime_vs_rails < 0
      puts "uptime_vs_rails: #{uptime_vs_rails.round(2)} seconds before rails started" if uptime_vs_rails >= 0
    end

  end

end
