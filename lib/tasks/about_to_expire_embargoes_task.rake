# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:about_to_expire_embargoes['{"skip_file_sets":true\,"email_owner":false\,"test_mode":true}']
  # bundle exec rake deepblue:about_to_expire_embargoes['{"skip_file_sets":true\,"email_owner":false\,"test_mode":true\,"expiration_lead_days":8}']
  desc 'About to expire embargoes.'
  task :about_to_expire_embargoes, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::AboutToExpireEmbargoesTask.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_task'
  require_relative '../../app/helpers/hyrax/embargo_helper'

  class AboutToExpireEmbargoesTask < AbstractTask
    include ::Hyrax::EmbargoHelper

    def initialize( options: {} )
      super( options: options )
    end

    def run
      @assets = Array( assets_under_embargo )
      @now = DateTime.now
      @email_owner = task_options_value( key: 'email_owner', default_value: true )
      @skip_file_sets = task_options_value( key: 'skip_file_sets', default_value: true )
      @test_mode = task_options_value( key: 'test_mode', default_value: true )
      @expiration_lead_days = task_options_value( key: 'expiration_lead_days' )
      about_to_expire_embargoes
    end

    def about_to_expire_embargoes
      if @expiration_lead_days.blank?
        about_to_expire_embargoes_for_lead_days( lead_days: 7 )
        about_to_expire_embargoes_for_lead_days( lead_days: 1 )
      else
        @expiration_lead_days = @expiration_lead_days.to_i
        if 0 < @expiration_lead_days
          about_to_expire_embargoes_for_lead_days( lead_days: @expiration_lead_days )
        else
          about_to_expire_embargoes_for_lead_days( lead_days: 7 )
          about_to_expire_embargoes_for_lead_days( lead_days: 1 )
        end
      end
    end

    def about_to_expire_embargoes_for_lead_days( lead_days: )
      puts "expiration lead days: #{lead_days}" if @test_mode
      # puts "The number of assets with under emboargo is: #{@assets.size}"
      # puts
      lead_date = @now + lead_days.days
      lead_date = lead_date.beginning_of_day
      lead_date_end = lead_date.end_of_day
      @assets.each_with_index do |asset,i|
        next if @skip_file_sets && "FileSet" == asset.model_name
        # puts "" if i == 0
        # puts "#{asset.class.name}" if i == 0
        # puts "#{asset.methods}" if i == 0
        # puts "" if i == 0
        # puts "#{i} - #{asset.id}, #{asset.model_name}, #{asset.human_readable_type}, #{asset.solr_document.title}, #{asset.embargo_release_date} (#{asset.embargo_release_date.class.name}), #{asset.visibility_after_embargo}"
        embargo_release_date = asset.embargo_release_date
        puts "embargo_release_date=#{embargo_release_date}"
        puts "DateTime.parse embargo_release_date=#{DateTime.parse embargo_release_date}"
        if embargo_release_date >= lead_date && embargo_release_date <= lead_date_end
          puts "about to call about_to_expire_embargo_email" if @test_mode
          about_to_expire_embargo_email( asset: asset,
                                         expiration_days: lead_days,
                                         email_owner: @email_owner,
                                         test_mode: @test_mode ) unless @test_mode
        end
      end
    end


  end

end
