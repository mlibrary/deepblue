# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:assets_under_embargo_report['{"skip_file_sets":false}']
  # bundle exec rake deepblue:assets_under_embargo_report['{"report_days_to_expiration":true}']
  desc 'Report assets under embargo.'
  task :assets_under_embargo_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::AssetsUnderEmbargoReportTask.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_report_task'
  require_relative '../../app/helpers/hyrax/embargo_helper'

  class AssetsUnderEmbargoReportTask < AbstractReportTask
    include ::Hyrax::EmbargoHelper

    def initialize( options: {} )
      super( options: options )
    end

    def run
      @skip_file_sets = task_options_value( key: 'skip_file_sets', default_value: true )
      @report_days_to_expiration = task_options_value( key: 'report_days_to_expiration', default_value: false )
      @now = DateTime.now
      @start_of_day = @now.beginning_of_day
      initialize_report_values
      write_report
    end

    def initialize_report_values
      @assets = Array( assets_under_embargo )
    end

    def write_report
      puts "The number of assets under embargo is: #{@assets.size}"
      puts
      @assets.each_with_index do |asset,i|
        next if @skip_file_sets && "FileSet" == asset.model_name
        puts "#{i} - #{asset.id}, #{asset.model_name}, #{asset.human_readable_type}, #{asset.solr_document.title} #{asset.embargo_release_date}, #{asset.visibility_after_embargo}"
        if @report_days_to_expiration
          embargo_release_date = asset_embargo_release_date( asset: asset )
          # puts "days to expiration: #{embargo_release_date - @start_of_day}"
          days_to_expiration = ((embargo_release_date - @start_of_day).to_f + 0.5).to_i
          puts "days to expiration: #{days_to_expiration}"
        end
      end
    end

  end

end
