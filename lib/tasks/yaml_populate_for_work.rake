# frozen_string_literal: true

require 'open-uri'

namespace :deepblue do

  # bundle exec rake deepblue:yaml_populate_from_work[f4752g72m,/deepbluedata-prep,true]
  desc 'Yaml populate from work'
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task
  task :yaml_populate_from_work, %i[ work_id target_dir export_files ] => :environment do |_task, args|
    # puts "upgrade_provenance_log", args.as_json
    task = Deepblue::YamlPopulateFromWork.new( work_id: args[:work_id],
                                               target_dir: args[:target_dir],
                                               export_files: args[:export_files] )
    task.run
  end

  # bundle exec rake deepblue:yaml_populate_from_multiple_works
  desc 'Yaml populate from multiple works'
  task yaml_populate_from_multiple_works: :environment do
    Deepblue::YamlPopulateFromMultipleWorks.run
  end

end

module Deepblue

  class YamlPopulateFromWork

    def initialize( work_id:, target_dir:, export_files: )
      @work_id = work_id
      @target_dir = target_dir
      @export_files = export_files.casecmp 'true'
    end

    def run
      MetadataHelper.yaml_generic_work_populate( generic_work: @work_id,
                                                 dir: @target_dir,
                                                 export_files: @export_files )
    end

  end

  # TODO: parametrize the work id
  # TODO: parametrize the target directory
  class YamlPopulateFromMultipleWorks

    def self.run
      ids = [ 'kh04dp82v', '7p88ch00j', '6108vb81z', 'v979v354p', 'x059c7753', 'gf06g3075', 't722h885b', '70795767w', '8p58pc92q', 'x920fx31k', 'j38607392' ]
      ids.each { |id| MetadataHelper.yaml_generic_work_populate( generic_work: id, export_files: true ) }
    end

  end

end
