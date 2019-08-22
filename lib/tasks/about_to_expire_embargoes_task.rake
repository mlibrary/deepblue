# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:deactivate_expired_embargoes['{"mode":"report"}']
  # bundle exec rake deepblue:deactivate_expired_embargoes['{"mode":"email"}']
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
      @seven_days_from_now = @now + 7.days
      @tomorrow = @now + 1.days
      @mode = task_options_value( key: 'mode', default_value: 'report' )
      about_to_expire_embargoes
    end

    def about_to_expire_embargoes
      puts "The number of assets with under emboargo is: #{@assets.size}"
      # puts
      @assets.each_with_index do |asset,i|
        next if @skip_file_sets && "FileSet" == asset.model_name
        puts "" if i == 0
        puts "#{asset.class.name}" if i == 0
        puts "#{asset.methods}" if i == 0
        puts "" if i == 0
        puts "#{i} - #{asset.id}, #{asset.model_name}, #{asset.human_readable_type}, #{asset.solr_document.title}, #{asset.embargo_release_date} (#{asset.embargo_release_date.class.name}), #{asset.visibility_after_embargo}"
        embargo_release_date = asset.embargo_release_date
        # model = asset.solr_document.to_model
        if embargo_release_date < @tomorrow
          about_to_expire_embargo_email( asset: asset, expiration_days: 1, mode: @mode )
        elsif embargo_release_date < @seven_days_from_now
          about_to_expire_embargo_email( asset: asset, expiration_days: 7, mode: @mode )
        end
      end
    end

  end

end
