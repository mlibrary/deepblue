# frozen_string_literal: true

require 'open-uri'

namespace :deepblue do

  # bundle exec rake deepblue:yaml_populate_from_collection[nk322d32h,/deepbluedata-prep,true]
  desc 'Yaml populate from collection'
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task
  task :yaml_populate_from_collection, %i[ collection_id target_dir export_files ] => :environment do |_task, args|
    # puts "upgrade_provenance_log", args.as_json
    args.with_defaults( collection_id: 'nk322d32h', target_dir: '/deepbluedata-prep', export_files: 'true' )
    task = Deepblue::YamlPopulateFromCollection.new( collection_id: args[:collection_id],
                                                     target_dir: args[:target_dir],
                                                     export_files: args[:export_files] )
    task.run
  end

  # bundle exec rake deepblue:yaml_populate_from_multiple_collections
  desc 'Yaml populate from multiple collections'
  task yaml_populate_from_multiple_collections: :environment do
    Deepblue::YamlPopulateFromMultipleCollections.run
  end

end

module Deepblue

  class YamlPopulateFromCollection

    def initialize( collection_id:, target_dir:, export_files: )
      @collection_id = collection_id
      @target_dir = target_dir
      @export_files = export_files.casecmp( 'true' ).zero?
    end

    def run
      puts "Exporting collection #{@collection_id} to '#{@target_dir}' with export files flag set to #{@export_files}"
      MetadataHelper.yaml_populate_collection( collection: @collection_id,
                                               dir: @target_dir,
                                               export_files: @export_files )
    end

  end

  class YamlPopulateFromCollectionTest

    def initialize
      @collection_id = 'nk322d32h'
      @target_dir = '/deepbluedata-prep'
      @export_files = true
    end

    def run
      MetadataHelper.yaml_populate_collection( collection: @collection_id,
                                               dir: @target_dir,
                                               export_files: @export_files )
    end

  end

  # TODO: parametrize the collection id
  # TODO: parametrize the target directory
  class YamlPopulateFromMultipleCollections

    def self.run
      ids = [ 'kh04dp82v', '7p88ch00j', '6108vb81z', 'v979v354p', 'x059c7753', 'gf06g3075', 't722h885b', '70795767w', '8p58pc92q', 'x920fx31k', 'j38607392' ]
      ids.each { |id| MetadataHelper.yaml_populate_collection( collection: id, export_files: true ) }
    end

  end

end
