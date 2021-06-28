# frozen_string_literal: true

module Deepblue

  module DiskUtilitiesHelper

    mattr_accessor :disk_utilities_helper_debug_verbose, default: false

    # returns count of dirs deleted (0 or 1)
    def self.delete_dir( dir_path, recursive: false )
      dirs_deleted = 0
      dir_path = dir_path.to_s
      return dirs_deleted unless Dir.exist? dir_path
      files = files_in_dir( dir_path )
      delete_files( *files )
      if recursive
        dirs = dirs_in_dir( dir_path )
        dirs.each do |dir|
          dirs_deleted += delete_dir( dir, recursive: true )
        end
      end
      begin
        Dir.delete dir_path
      rescue Errno::ENOTEMPTY
        # Ignore: dir is not empty
      end
      dirs_deleted += Dir.exist?( dir_path ) ? 0 : 1
      return dirs_deleted
    end

    # returns count of dirs deleted
    def self.delete_dirs( *dirs, recursive: false )
      deleted_count = 0
      dirs.each do |dirs|
        deleted_count += delete_dir( dir, recursive: recursive )
      end
      deleted_count
    end

    # returns count of dirs deleted
    def self.delete_dirs_glob_regexp( base_dir:, glob: '*', filename_regexp: nil, days_old: 0, recursive: false )
      base_dir = base_dir.to_s
      dirs = dirs_in_dir( base_dir, glob: glob )
      if regexp.present?
        dirs = dirs.select do |dir|
          dir = File.basename file
          dir =~ filename_regexp
        end
      end
      delete_dirs_older_than( dirs, days_old: days_old, recursive: recursive )
    end

    # returns count of dirs deleted
    def self.delete_dirs_older_than( *dirs, days_old:, recursive: false )
      return delete_dirs( *files, recursive: recursive ) if days_old <= 0
      older_than = DateTime.now - days_old.days
      dirs = dirs.select { |dir| File.mtime( dir ) < older_than }
      delete_files( *dirs, recursive: recursive )
    end

    # returns count of files deleted (0 or 1)
    def self.delete_file( file_path )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_path=#{file_path}",
                                             "" ], bold_puts: true if disk_utilities_helper_debug_verbose
      file_path = file_path.to_s
      return 0 unless File.file? file_path
      File.delete file_path
      rv = File.exists?( file_path ) ? 0 : 1
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: true if disk_utilities_helper_debug_verbose
      return rv
    end

    # returns count of files deleted (0 or 1)
    def self.delete_files( *files )
      deleted_count = 0
      files.each do |file|
        deleted_count += delete_file( file )
      end
      deleted_count
    end

    # returns count of files deleted
    def self.delete_files_glob_regexp( base_dir:, glob: '*', filename_regexp: nil, days_old: 0 )
      base_dir = base_dir.to_s
      files = Dir.glob( File.join( base_dir, glob )  )
      if regexp.present?
        files = files.select do |file|
          file = File.basename file
          file =~ filename_regexp
        end
      end
      delete_files_older_than( *files, days_old: days_old )
    end

    # returns count of files deleted
    def self.delete_files_in_dir( dir_path, delete_subdirs: false )
      dir_path = dir_path.to_s
      return 0 unless Dir.exist? dir_path
      files = files_in_dir( dir_path )
      deleted_count = 0
      deleted_count += delete_files( *files )
      if delete_subdirs
        dirs = files_in_dir( dir_path, include_dirs: true )
        deleted_count += delete_dirs( *dirs )
      end
      return deleted_count
    end

    # returns count of files deleted
    def self.delete_files_older_than( *files, days_old: )
      return delete_files( *files ) if days_old <= 0
      older_than = DateTime.now - days_old.days
      files = files.select { |file| File.mtime( file ) < older_than }
      delete_files( *files )
    end

    # returns array of files
    def self.dirs_in_dir( dir_path, glob: '*' )
      dir_path = dir_path.to_s
      dirs = Dir.glob( File.join( dir_path, glob )  )
      dirs = dirs.select { |dir| Dir.exist? dir }
      return dirs
    end

    # returns array of files
    def self.files_in_dir( dir_path, glob: '*', include_dirs: false )
      dir_path = dir_path.to_s
      files = Dir.glob( File.join( dir_path, glob )  )
      files = files.select { |file| File.file? file } unless include_dirs
      return files
    end

    def self.files_in_tmp_derivative( older_than_days: 7 )
      path = tmp_derivatives_path
      path = Pathname path
      # # files = Dir.glob( (path.join '*').to_s )
      # files = Dir.glob( path.join( '?' * 9 ).to_s )
      # # files = Dir.glob( path.join("DeepBlueData_#{'?' * 9}").to_s )
      # # dirs = Dir.glob( path.join("0?").to_s )
      # files = Dir.glob( path.join("mini_magick*").to_s )
      # delete_files_older_than( files, days_old: 7 )
      # mapped = files.map { |f| File.mtime f }
      older_than_days = 7 if older_than_days.nil?
      # older_than = DateTime.now - older_than_days.days
      # select = files.select { |f| File.mtime(f) < older_than }
      # select.each { |dir_path| delete_dir( dir_path, delete_dir: true ) }

      delete_dirs_glob_regexp( base_dir: path, glob: '?' * 9, filename_regexp: /^[0-9a-z]{9}$/, days_old: older_than_days )
      delete_files_glob_regexp( base_dir: path, glob: "mini_magick*", days_old: older_than_days )
      delete_files_glob_regexp( base_dir: path, glob: "apache-tika-*.tmp", days_old: older_than_days )

    end

    def self.tmp_derivatives_path
      Hydra::Derivatives.temp_file_base
    end

  end

end
