# frozen_string_literal: true

require_relative './yaml_populate_for_work'

namespace :deepblue do

  # bundle exec rake deepblue:yaml_populate_from_work[f4752g72m,'{"target_dir":"/deepbluedata-dataden/download-prep"\,"export_files":true\,"mode":"build"}']
  desc 'Yaml populate from work'
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task
  task :yaml_populate_from_work, %i[ id options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromWork.new( id: args[:id], options: args[:options] )
    task.run
  end

  # bundle exec rake deepblue:yaml_populate_from_multiple_works['f4752g72m f4752g72m','{"target_dir":"/deepbluedata-dataden/download-prep"\,"export_files":true\,"mode":"build"}']
  desc 'Yaml populate from multiple works (ids separated by spaces)'
  task :yaml_populate_from_multiple_works, %i[ ids options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromMultipleWorks.new( ids: args[:ids], options: args[:options] )
    task.run
  end

  # bundle exec rake deepblue:yaml_populate_from_all_works['{"target_dir":"/deepbluedata-dataden/download-prep"\,"export_files":false\,"mode":"build"}']
  desc 'Yaml populate from all works'
  task :yaml_populate_from_all_works, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::YamlPopulateFromAllWorks.new( options: args[:options] )
    task.run
  end

end
