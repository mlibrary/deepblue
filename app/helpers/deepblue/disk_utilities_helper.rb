# frozen_string_literal: true

module Deepblue

  module DiskUtilitiesHelper

    mattr_accessor :disk_utilities_helper_debug_verbose, default: false
    mattr_accessor :disk_utilities_helper_bold_puts, default: false

    def self.add_msg( msg_queue: nil, prefix:, path:, test_mode: false )
      return if msg_queue.nil? && !test_mode
      msg = "#{prefix}#{path}"
      puts msg if test_mode
      msg_queue << msg unless msg_queue.nil?
    end

    # returns count of dirs deleted (0 or 1)
    def self.delete_dir( dir_path,
                         debug_verbose: disk_utilities_helper_debug_verbose,
                         msg_queue: nil,
                         recursive: false,
                         test_mode: false,
                         verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dir_path=#{dir_path}",
                                             "recursive=#{recursive}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      dirs_deleted = 0
      dir_path = dir_path.to_s
      dir_exist = Dir.exist? dir_path
      add_msg( msg_queue: msg_queue, prefix: '!Dir.exist? ', path: dir_path, test_mode: test_mode ) if !dir_exist && verbose
      return dirs_deleted unless dir_exist
      files = files_in_dir( dir_path )
      delete_files( *files,
                    debug_verbose: debug_verbose,
                    msg_queue: msg_queue,
                    test_mode: test_mode,
                    verbose: verbose )
      if recursive
        dirs = dirs_in_dir( dir_path, debug_verbose: debug_verbose, test_mode: test_mode )
        dirs.each do |dir|
          dirs_deleted += delete_dir( dir,
                                      recursive: true,
                                      debug_verbose: debug_verbose,
                                      msg_queue: msg_queue,
                                      test_mode: test_mode,
                                      verbose: verbose )
        end
      end
      begin
        Dir.delete dir_path unless test_mode
        add_msg( msg_queue: msg_queue, prefix: 'Dir.delete ', path: dir_path, test_mode: test_mode )
      rescue Errno::ENOTEMPTY
        # Ignore: dir is not empty
        add_msg( msg_queue: msg_queue, prefix: 'Not empty dir: ', path: dir_path, test_mode: test_mode ) if verbose
      end
      dirs_deleted += Dir.exist?( dir_path ) ? 0 : 1
      return dirs_deleted
    end

    # returns count of dirs deleted
    def self.delete_dirs( *dirs,
                          debug_verbose: disk_utilities_helper_debug_verbose,
                          recursive: false,
                          msg_queue: nil,
                          test_mode: false,
                          verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dirs=#{dirs}",
                                             "recursive=#{recursive}",
                                             "test_mode=#{test_mode}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      deleted_count = 0
      dirs.each do |dir|
        deleted_count += delete_dir( dir,
                                     debug_verbose: debug_verbose,
                                     msg_queue: msg_queue,
                                     recursive: recursive,
                                     test_mode: test_mode,
                                     verbose: verbose )
      end
      deleted_count
    end

    # returns count of dirs deleted
    def self.delete_dirs_glob_regexp( base_dir:,
                                      days_old: 0,
                                      debug_verbose: disk_utilities_helper_debug_verbose,
                                      filename_regexp: nil,
                                      glob: '*',
                                      msg_queue: nil,
                                      recursive: false,
                                      test_mode: false,
                                      verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_dir=#{base_dir}",
                                             "glob=#{glob}",
                                             "filename_regexp=#{filename_regexp}",
                                             "days_old=#{days_old}",
                                             "recursive=#{recursive}",
                                             "test_mode=#{test_mode}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      base_dir = base_dir.to_s
      dirs = dirs_in_dir( base_dir, glob: glob, debug_verbose: debug_verbose, test_mode: test_mode )
      if filename_regexp.present?
        dirs = dirs.select do |dir|
          dir = File.basename dir
          dir =~ filename_regexp
        end
      end
      delete_dirs_older_than( *dirs,
                              days_old: days_old,
                              debug_verbose: debug_verbose,
                              msg_queue: msg_queue,
                              recursive: recursive,
                              test_mode: test_mode,
                              verbose: verbose )
    end

    # returns count of dirs deleted
    def self.delete_dirs_older_than( *dirs,
                                     days_old:,
                                     debug_verbose: disk_utilities_helper_debug_verbose,
                                     msg_queue: nil,
                                     recursive: false,
                                     test_mode: false,
                                     verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dirs=#{dirs}",
                                             "days_old=#{days_old}",
                                             "recursive=#{recursive}",
                                             "test_mode=#{test_mode}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      return delete_dirs( *files,
                          debug_verbose: debug_verbose,
                          msg_queue: msg_queue,
                          recursive: recursive,
                          test_mode: test_mode,
                          verbose: verbose ) if days_old <= 0
      older_than = DateTime.now - days_old.days
      dirs = dirs.select do |dir|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "dir=#{dir}",
                                               "File.mtime( dir ) < older_than=#{File.mtime( dir ) < older_than}",
                                               "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
        File.mtime( dir ) < older_than
      end
      delete_dirs( *dirs,
                   debug_verbose: debug_verbose,
                   msg_queue: msg_queue,
                   recursive: recursive,
                   test_mode: test_mode,
                   verbose: verbose )
    end

    # returns count of files deleted (0 or 1)
    def self.delete_file( file_path,
                          debug_verbose: disk_utilities_helper_debug_verbose,
                          msg_queue: nil,
                          test_mode: false,
                          verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_path=#{file_path}",
                                             "test_mode=#{test_mode}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      file_path = file_path.to_s
      is_a_file = File.file? file_path
      add_msg( msg_queue: msg_queue, prefix: '!File.file? ', path: file_path, test_mode: test_mode ) if !is_a_file && verbose
      return 0 unless is_a_file
      File.delete file_path unless test_mode
      add_msg( msg_queue: msg_queue, prefix: 'File.delete ', path: file_path, test_mode: test_mode )
      rv = File.exists?( file_path ) ? 0 : 1
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      return rv
    end

    # returns count of files deleted (0 or 1)
    def self.delete_files( *files,
                           debug_verbose: disk_utilities_helper_debug_verbose,
                           msg_queue: nil,
                           test_mode: false,
                           verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "test_mode=#{test_mode}",
                                             "vebose=#{verbose}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      deleted_count = 0
      files.each do |file|
        deleted_count += delete_file( file,
                                      debug_verbose: debug_verbose,
                                      msg_queue: msg_queue,
                                      test_mode: test_mode,
                                      verbose: verbose )
      end
      deleted_count
    end

    # returns count of files deleted
    def self.delete_files_glob_regexp( base_dir:,
                                       days_old: 0,
                                       debug_verbose: disk_utilities_helper_debug_verbose,
                                       filename_regexp: nil,
                                       glob: '*',
                                       msg_queue: nil,
                                       test_mode: false,
                                       verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_dir=#{base_dir}",
                                             "glob=#{glob}",
                                             "filename_regexp=#{filename_regexp}",
                                             "days_old=#{days_old}",
                                             "test_mode=#{test_mode}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      base_dir = base_dir.to_s
      files = Dir.glob( File.join( base_dir, glob )  )
      if filename_regexp.present?
        files = files.select do |file|
          file = File.basename file
          file =~ filename_regexp
        end
      end
      delete_files_older_than( *files,
                               days_old: days_old,
                               debug_verbose: debug_verbose,
                               msg_queue: msg_queue,
                               test_mode: test_mode,
                               verbose: verbose )
    end

    # returns count of files deleted
    def self.delete_files_in_dir( dir_path,
                                  delete_subdirs: false,
                                  debug_verbose: disk_utilities_helper_debug_verbose,
                                  msg_queue: nil,
                                  test_mode: false,
                                  verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dir_path=#{dir_path}",
                                             "delete_subdirs=#{delete_subdirs}",
                                             "test_mode=#{test_mode}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      dir_path = dir_path.to_s
      return 0 unless Dir.exist? dir_path
      files = files_in_dir( dir_path )
      deleted_count = 0
      deleted_count += delete_files( *files,
                                     debug_verbose: debug_verbose,
                                     msg_queue: msg_queue,
                                     test_mode: test_mode,
                                     verbose: verbose )
      if delete_subdirs
        dirs = files_in_dir( dir_path, include_dirs: true )
        deleted_count += delete_dirs( *dirs,
                                      debug_verbose: debug_verbose,
                                      msg_queue: nil,
                                      test_mode: test_mode,
                                      verbose: verbose )
      end
      return deleted_count
    end

    # returns count of files deleted
    def self.delete_files_older_than( *files,
                                      days_old:,
                                      debug_verbose: disk_utilities_helper_debug_verbose,
                                      msg_queue: nil,
                                      test_mode: false,
                                      verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "days_old=#{days_old}",
                                             "test_mode=#{test_mode}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      return delete_files( *files,
                           debug_verbose: debug_verbose,
                           msg_queue: msg_queue,
                           test_mode: test_mode,
                           verbose: verbose ) if days_old <= 0
      older_than = DateTime.now - days_old.days
      files = files.select { |file| File.mtime( file ) < older_than }
      delete_files( *files,
                    debug_verbose: debug_verbose,
                    msg_queue: msg_queue,
                    test_mode: test_mode,
                    verbose: verbose )
    end

    # returns array of files
    def self.dirs_in_dir( dir_path, glob: '*', debug_verbose: disk_utilities_helper_debug_verbose, test_mode: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dir_path=#{dir_path}",
                                             "glob=#{glob}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      dir_path = dir_path.to_s
      dirs = Dir.glob( File.join( dir_path, glob )  )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dirs=#{dirs}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      dirs = dirs.select { |dir| Dir.exist? dir }
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dirs=#{dirs}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      return dirs
    end

    def self.expand_id_path( id, base_dir: nil )
      arr = id.split('').each_slice(2).map(&:join)
      rv = File.join arr
      return rv unless base_dir.present?
      rv = File.join base_dir, rv
      return rv
    end

    # returns array of files
    def self.files_in_dir( dir_path,
                           glob: '*',
                           include_dirs: false,
                           debug_verbose: disk_utilities_helper_debug_verbose,
                           test_mode: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dir_path=#{dir_path}",
                                             "glob=#{glob}",
                                             "include_dirs=#{include_dirs}",
                                             "test_mode=#{test_mode}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      dir_path = dir_path.to_s
      files = Dir.glob( File.join( dir_path, glob )  )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      files = files.select { |file| File.file? file } unless include_dirs
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files=#{files}",
                                             "" ], bold_puts: disk_utilities_helper_bold_puts if debug_verbose
      return files
    end

    def self.mkdir( target_dir )
      Dir.mkdir( target_dir ) unless Dir.exist? target_dir
    end

    def self.mkdirs( target_dir )
      FileUtils.mkdir_p target_dir unless Dir.exist? target_dir
    end

    def self.tmp_derivatives_path
      Hydra::Derivatives.temp_file_base
    end

  end

end
