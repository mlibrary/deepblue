# frozen_string_literal: true

require_relative './ml_populate_for_collection'

namespace :deepblue do

  # bundle exec rake deepblue:yaml_populate_from_collection[nk322d32h,/deepbluedata-prep,true]
  desc 'Yaml populate from collection'
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task
  task :yaml_populate_from_collection, %i[ id options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromCollection.new( id: args[:id], options: args[:options] )
    task.run
  end

  # bundle exec rake umrdr:yaml_populate_from_multiple_collections['f4752g72m f4752g72m',/deepbluedata-prep,true]
  desc 'Yaml populate from multiple collections (ids separated by spaces)'
  task :yaml_populate_from_multiple_collections, %i[ ids options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromMultipleCollections.new( ids: args[:ids], options: args[:options] )
    task.run
  end

  # bundle exec rake deepblue:yaml_populate_from_all_collections['{"target_dir":"/deepbluedata-prep"\,"export_files":false\,"mode":"build"}']
  desc 'Yaml populate from all collections'
  task :yaml_populate_from_all_collections, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromAllCollections.new( options: args[:options] )
    task.run
  end

end
