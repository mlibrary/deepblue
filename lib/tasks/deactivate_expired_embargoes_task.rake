# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:deactivate_expired_embargoes['{"test_mode":true}']
  # bundle exec rake deepblue:deactivate_expired_embargoes['{"skip_file_sets":false\,"test_mode":true}']
  desc 'Deactivate expired embargoes.'
  task :deactivate_expired_embargoes, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::DeactivateExpiredEmbargoesTask.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_task'
  require_relative '../../app/helpers/hyrax/embargo_helper'

  class DeactivateExpiredEmbargoesTask < AbstractTask
    include ::Hyrax::EmbargoHelper

    def initialize( options: {} )
      super( options: options )
    end

    def run
      @assets = Array( assets_with_expired_embargoes )
      @now = DateTime.now
      @email_owner = task_options_value( key: 'email_owner', default_value: true )
      @skip_file_sets = task_options_value( key: 'skip_file_sets', default_value: true )
      @test_mode = task_options_value( key: 'test_mode', default_value: true )
      deactivate_expired_embargoes
    end

    def deactivate_expired_embargoes
      puts "The number of assets with expired embargoes is: #{@assets.size}"
      # puts
      @assets.each_with_index do |asset,i|
        next if @skip_file_sets && "FileSet" == asset.model_name
        puts "" if i == 0
        puts "#{asset.class.name}" if i == 0
        puts "#{asset.methods}" if i == 0
        puts "" if i == 0
        puts "#{i} - #{asset.id}, #{asset.model_name}, #{asset.human_readable_type}, #{asset.solr_document.title} #{asset.embargo_release_date}, #{asset.visibility_after_embargo}"
        model = asset.solr_document.to_model
        deactivate_embargo( curation_concern: model,
                            copy_visibility_to_files: true,
                            email_owner: @email_owner,
                            test_mode: @test_mode )
      end
    end

  end

end
