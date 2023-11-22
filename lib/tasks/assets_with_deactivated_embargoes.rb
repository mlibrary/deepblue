# frozen_string_literal: true

# namespace :deepblue do
#
#   # bundle exec rake deepblue:assets_with_deactivated_embargoes['{"skip_file_sets":false}']
#   desc 'Report assets with deactivated embargoes.'
#   task :assets_with_deactivated_embargoes, %i[ options ] => :environment do |_task, args|
#     args.with_defaults( options: '{}' )
#     options = args[:options]
#     task = Deepblue::AssetsWithDeactivatedEmbargoesReportTask.new( options: options )
#     task.run
#   end
#
# end

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_report_task'
  require_relative '../../app/helpers/hyrax/embargo_helper'

  class AssetsWithDeactivatedEmbargoesReportTask < AbstractReportTask
    include ::Hyrax::EmbargoHelper

    def initialize( options: {} )
      super( options: options )
    end

    def run
      @skip_file_sets = task_options_value( key: 'skip_file_sets', default_value: true )
      initialize_report_values
      write_report
    end

    def initialize_report_values
      @assets = Array( assets_with_deactivated_embargoes )
    end

    def write_report
      puts "The number of assets with deactivated embargoes is: #{@assets.size}"
      puts
      @assets.each_with_index do |asset,i|
        next if @skip_file_sets && "FileSet" == asset.model_name
        # puts "" if i == 0
        # puts "#{asset.class.name}" if i == 0
        # puts "#{asset.methods}" if i == 0
        # puts "" if i == 0
        puts "#{i} - #{asset.id}, #{asset.model_name}, #{asset.human_readable_type}, #{asset.solr_document.title} #{asset.embargo_release_date}, #{asset.visibility_after_embargo}"
      end
    end

  end

end
