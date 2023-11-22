# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:uptime_report
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

  require_relative '../../app/tasks/deepblue/abstract_task'
  require_relative '../../app/services/deepblue/uptime_service'

  class UptimeReport < AbstractTask

    attr_accessor :options

    def initialize( options: )
      super( options: options )
    end

    def run
      puts "ARGV=#{ARGV}"
      sleep_value = @options["sleep"]
      if sleep_value.present?
        puts "sleeping for #{sleep_value.to_i} seconds"
        sleep sleep_value.to_i
      end
      puts "Rails.const_defined? 'Console' = #{Rails.const_defined? 'Console'}"
      puts "Rails.const_defined? 'Server' = #{Rails.const_defined? 'Server'}"
      puts "program_load_timestamp: #{UptimeService.program_load_timestamp}"
      puts "program_name: #{UptimeService.program_name} with arg1=#{UptimeService.program_arg1}"
      puts "uptime_timestamp_file_path_self=#{UptimeService.uptime_timestamp_file_path_self}"
      puts "uptime: #{UptimeService.uptime.round(2)} seconds"
      uptime_vs_rails = UptimeService.uptime_vs_rails
      puts "rails is not running" if uptime_vs_rails.nil?
      puts
      UptimeService.uptime_timestamp_files.each do |file|
        puts UptimeService.uptime_for_file_human_readable( file: file )
      end
      puts
      puts "Uptime readable: #{TimeDifference.between( Time.now, UptimeService.program_load_timestamp ).humanize}"
      return if uptime_vs_rails.nil?
      puts "uptime_vs_rails: #{-uptime_vs_rails.round(2)} seconds after rails started" if uptime_vs_rails < 0
      puts "uptime_vs_rails: #{uptime_vs_rails.round(2)} seconds before rails started" if uptime_vs_rails >= 0
      puts
    end

  end

end
