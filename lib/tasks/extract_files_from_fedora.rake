# frozen_string_literal: true

namespace :deepblue do

  desc 'Extract files from fedora 01'
  task extract_files_01: :environment do
    Deepblue::ExtractFilesFromFedora01.run
  end

end

module Deepblue

  require 'open-uri'

  # TODO: parametrize the work id
  # TODO: parametrize the target directory
  class ExtractFilesFromFedora01
    def self.run
      # id = 'jh343s28d'
      id = 'wp988j816'
      puts "id=#{id}"
      w = TaskHelper.work_find( id: id )
      base = "/deepbluedata-prep"
      tmp = "#{base}/fedora-extract/#{id}"
      puts "tmp=#{tmp}"
      ensure_dirs_exist( base, "#{base}/fedora-extract", tmp )
      files_extracted = {}
      w.file_sets.each do |file_set|
        begin
          file = file_set.files[0]
          target_file_name = TaskHelper.target_file_name( file_set: file_set, files_extracted: files_extracted )
          # target_file_name = file_set.label
          # if files_extracted.key? target_file_name
          #   dup_count = 1
          #   base_ext = File.extname target_file_name
          #   base_target_file_name = File.basename target_file_name, base_ext
          #   target_file_name = base_target_file_name + "_" + dup_count.to_s.rjust( 3, '0' ) + base_ext
          #   while files_extracted.key? target_file_name
          #     dup_count += 1
          #     target_file_name = base_target_file_name + "_" + dup_count.to_s.rjust( 3, '0' ) + base_ext
          #   end
          # end
          # files_extracted.store( target_file_name, true )
          target_file = "#{tmp}/#{target_file_name}"
          source_uri = file.uri.value
          puts "copy #{target_file} << #{source_uri}"
          bytes_copied = ExportFilesHelper.export_file_uri( source_uri: source_uri, target_file: target_file )
          puts "bytes copied #{bytes_copied}"
        rescue Exception => e # rubocop:disable Lint/RescueException
          # STDERR.puts "UpdateWorksTotalFileSizes #{e.class}: #{e.message}"
          puts "Exception: #{e.class}: #{e.message}"
        end
      end
    end

  end

end
