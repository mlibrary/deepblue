require 'open-uri'

desc 'Yaml populate from work'
task :yaml_populate_from_work => :environment do
  Umrdr::YamlPopulateFromWork.run
end

desc 'Yaml populate from multiple works'
task :yaml_populate_from_multiple_works => :environment do
  Umrdr::YamlPopulateFromWork.run
end

module Umrdr

  # TODO: parametrize the work id
  # TODO: parametrize the target directory
  class YamlPopulateFromWork

    def self.run
      MetadataHelper.yaml_generic_work_populate( 'j6731380t', export_files: true )
    end

  end

  # TODO: parametrize the work id
  # TODO: parametrize the target directory
  class YamlPopulateFromMultipleWorks

    def self.run
      ids = [ 'kh04dp82v', '7p88ch00j', '6108vb81z', 'v979v354p', 'x059c7753', 'gf06g3075', 't722h885b', '70795767w', '8p58pc92q', 'x920fx31k', 'j38607392' ]
      ids.each { |id| MetadataHelper.yaml_generic_work_populate( id, export_files: true ) }
    end

  end

end
