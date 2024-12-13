# frozen_string_literal: true

module Deepblue

  module DiskUtilitiesHelper

    mattr_accessor :disk_utilities_helper_debug_verbose, default: false
    # mattr_accessor :disk_utilities_helper_bold_puts, default: false

    def self.add_msg( msg_handler:, prefix:, path:, test_mode: false )
      msg_handler.msg "#{prefix}#{path}"
    end

    # returns count of dirs deleted (0 or 1)
    def self.delete_dir( dir_path:, msg_handler:, recursive: false, test_mode: false )
      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dir_path=#{dir_path}",
                                             "recursive=#{recursive}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      dirs_deleted = 0
      dir_path = dir_path.to_s
      dir_exist = Dir.exist? dir_path
      add_msg( msg_handler: msg_handler, prefix: '!Dir.exist? ', path: dir_path ) if !dir_exist && msg_handler.verbose
      return dirs_deleted unless dir_exist
      files = files_in_dir( dir_path: dir_path, msg_handler: msg_handler, test_mode: test_mode )
      delete_files( files: files, msg_handler: msg_handler, test_mode: test_mode )
      if recursive
        dirs = dirs_in_dir( dir_path: dir_path, msg_handler: msg_handler, test_mode: test_mode )
        dirs.each do |dir|
          dirs_deleted += delete_dir( dir_path: dir, recursive: true, msg_handler: msg_handler, test_mode: test_mode )
        end
      end
      begin
        Dir.delete dir_path unless test_mode
        add_msg( msg_handler: msg_handler, prefix: 'Dir.delete ', path: dir_path )
      rescue Errno::ENOTEMPTY
        # Ignore: dir is not empty
        add_msg( msg_handler: msg_handler, prefix: 'Not empty dir: ', path: dir_path ) if msg_handler.verbose
      end
      dirs_deleted += Dir.exist?( dir_path ) ? 0 : 1
      return dirs_deleted
    end

    # returns count of dirs deleted
    def self.delete_dirs( dirs:, recursive: false, msg_handler:, test_mode: false )
      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dirs=#{dirs}",
                                             "recursive=#{recursive}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      dirs = Array( dirs )
      deleted_count = 0
      dirs.each do |dir|
        deleted_count += delete_dir( dir_path: dir, msg_handler: msg_handler, recursive: recursive, test_mode: test_mode )
      end
      deleted_count
    end

    # returns count of dirs deleted
    def self.delete_dirs_glob_regexp( base_dir:,
                                      days_old: 0,
                                      filename_regexp: nil,
                                      glob: '*',
                                      dotmatch: false,
                                      msg_handler:,
                                      recursive: false,
                                      test_mode: false )

      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_dir=#{base_dir}",
                                             "glob=#{glob}",
                                             "dotmatch=#{dotmatch}",
                                             "filename_regexp=#{filename_regexp}",
                                             "days_old=#{days_old}",
                                             "recursive=#{recursive}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      base_dir = base_dir.to_s
      dirs = dirs_in_dir( dir_path: base_dir, glob: glob, dotmatch: dotmatch, msg_handler: msg_handler, test_mode: test_mode )
      if filename_regexp.present?
        dirs = dirs.select do |dir|
          dir = File.basename dir
          dir =~ filename_regexp
        end
      end
      delete_dirs_older_than( dirs: dirs,
                              days_old: days_old,
                              msg_handler: msg_handler,
                              recursive: recursive,
                              test_mode: test_mode )
    end

    # returns count of dirs deleted
    def self.delete_dirs_older_than( dirs:, days_old:, msg_handler:, recursive: false, test_mode: false )
      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dirs=#{dirs}",
                                             "days_old=#{days_old}",
                                             "recursive=#{recursive}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      return delete_dirs( dirs: dirs, msg_handler: msg_handler, recursive: recursive, test_mode: test_mode ) if days_old <= 0
      dirs = Array( dirs )
      older_than = DateTime.now - days_old.days
      dirs = dirs.select do |dir|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "dir=#{dir}",
                                               "File.mtime( dir ) < older_than=#{File.mtime( dir ) < older_than}",
                                               "" ], bold_puts: msg_handler.to_console if debug_verbose
        File.mtime( dir ) < older_than
      end
      delete_dirs( dirs: dirs, msg_handler: msg_handler, recursive: recursive, test_mode: test_mode )
    end

    # returns count of files deleted (0 or 1)
    def self.delete_file( file_path:, msg_handler:, test_mode: false )
      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_path=#{file_path}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      file_path = file_path.to_s
      is_a_file = File.file? file_path
      add_msg( msg_handler: msg_handler, prefix: '!File.file? ', path: file_path ) if !is_a_file && msg_handler.verbose
      return 0 unless is_a_file
      File.delete file_path unless test_mode
      add_msg( msg_handler: msg_handler, prefix: 'File.delete ', path: file_path )
      rv = File.exist?( file_path ) ? 0 : 1
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      return rv
    end

    # returns count of files deleted (0 or 1)
    def self.delete_files( files:, msg_handler:, test_mode: false )
      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      files = Array( files )
      deleted_count = 0
      files.each do |file|
        deleted_count += delete_file( file_path: file, msg_handler: msg_handler )
      end
      deleted_count
    end

    # returns count of files deleted
    def self.delete_files_glob_regexp( base_dir:,
                                       days_old: 0,
                                       filename_regexp: nil,
                                       glob: '*',
                                       dotmatch: false,
                                       msg_handler:,
                                       test_mode: false )

      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_dir=#{base_dir}",
                                             "glob=#{glob}",
                                             "dotmatch=#{dotmatch}",
                                             "filename_regexp=#{filename_regexp}",
                                             "days_old=#{days_old}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      base_dir = base_dir.to_s
      if dotmatch
        files = Dir.glob( File.join( base_dir, glob ), File::FNM_DOTMATCH )
      else
        files = Dir.glob( File.join( base_dir, glob ) )
      end
      if filename_regexp.present?
        files = files.select do |file|
          file = File.basename file
          file =~ filename_regexp
        end
      end
      delete_files_older_than( files: files, days_old: days_old, msg_handler: msg_handler, test_mode: test_mode )
    end

    # returns count of files deleted
    def self.delete_files_in_dir( dir_path:, delete_subdirs: false, msg_handler:, test_mode: false )
      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dir_path=#{dir_path}",
                                             "delete_subdirs=#{delete_subdirs}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      dir_path = dir_path.to_s
      return 0 unless Dir.exist? dir_path
      files = files_in_dir( dir_path: dir_path, msg_handler: msg_handler, test_mode: test_mode )
      deleted_count = 0
      deleted_count += delete_files( files: files, msg_handler: msg_handler, test_mode: test_mode )
      if delete_subdirs
        dirs = files_in_dir( dir_path: dir_path, include_dirs: true, msg_handler: msg_handler, test_mode: test_mode )
        deleted_count += delete_dirs( dirs: dirs, msg_handler: msg_handler, test_mode: test_mode )
      end
      return deleted_count
    end

    # returns count of files deleted
    def self.delete_files_older_than( files:, days_old:, msg_handler:, test_mode: false )
      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "days_old=#{days_old}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      return delete_files( files: files, msg_handler: msg_handler, test_mode: test_mode ) if days_old <= 0
      files = Array( files )
      older_than = DateTime.now - days_old.days
      files = files.select { |file| File.mtime( file ) < older_than }
      delete_files( files: files, msg_handler: msg_handler, test_mode: test_mode )
    end

    # returns array of files
    def self.dirs_in_dir( dir_path:, glob: '*', dotmatch: false, msg_handler:, test_mode: false )
      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dir_path=#{dir_path}",
                                             "glob=#{glob}",
                                             "dotmatch=#{dotmatch}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      dir_path = dir_path.to_s
      if dotmatch
        dirs = Dir.glob( File.join( dir_path, glob ), File::FNM_DOTMATCH )
      else
        dirs = Dir.glob( File.join( dir_path, glob ) )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dirs=#{dirs}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      dirs = dirs.select { |dir| Dir.exist? dir }
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dirs=#{dirs}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      return dirs
    end

    def self.expand_id_path( id:, base_dir: nil )
      arr = id.split('').each_slice(2).map(&:join)
      rv = File.join arr
      return rv unless base_dir.present?
      rv = File.join base_dir, rv
      return rv
    end

    def self.file_exists?( file )
      return File.exist?( file )
    end

    # returns array of files
    def self.files_in_dir( dir_path:, glob: '*', dotmatch: false, include_dirs: false, msg_handler:, test_mode: false )
      debug_verbose = msg_handler.debug_verbose || disk_utilities_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dir_path=#{dir_path}",
                                             "glob=#{glob}",
                                             "dotmatch=#{dotmatch}",
                                             "include_dirs=#{include_dirs}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      dir_path = dir_path.to_s
      if dotmatch
        files = Dir.glob( File.join( dir_path, glob ), File::FNM_DOTMATCH )
      else
        files = Dir.glob( File.join( dir_path, glob ) )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      files = files.select { |file| File.file? file } unless include_dirs
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      return files
    end

    def self.mkdir( target_dir )
      Dir.mkdir( target_dir ) unless Dir.exist? target_dir
    end

    def self.mkdirs( target_dir )
      return if Dir.exists? target_dir
      return if File.symlink? target_dir
      FileUtils.mkdir_p target_dir
    end

    def self.tmp_derivatives_path
      Hydra::Derivatives.temp_file_base
    end

    @@tmp_uploads_path = nil

    def self.tmp_uploads_path
      @@tmp_uploads_path ||= Hyrax.config.upload_path.call.join( 'hyrax', 'uploaded_file', 'file' ).to_s
    end

  end

end
