# frozen_string_literal: true

module FileUtilsHelper
  # Use this to create a gap between the code and FileUtils, which is useful for writing specs, as
  # creating an expect against FileUtils (or File/Dir etc) causes issues in the spec

  def self.copy( src, dest, preserve: nil, noop: nil, verbose: nil )
    FileUtils.copy( src, dest, preserve: preserve, noop: noop, verbose: verbose )
  end

  def self.cp( src, dest, preserve: nil, noop: nil, verbose: nil )
    FileUtils.cp( src, dest, preserve: preserve, noop: noop, verbose: verbose )
  end

  def self.dir_exist?( dirpath )
    Dir.exist?( dirpath )
  end

  def self.dir_exists?( dirpath )
    Dir.exist?( dirpath )
  end

  def self.file_exist?( file_name )
    File.exist?( file_name )
  end

  def self.file_exists?( file_name )
    File.exist?( file_name )
  end

  def self.join( string, *args )
    File.join( string, args )
  end

  def self.ln_s( src, dest, force: nil, relative: false, target_directory: true, noop: nil, verbose: nil )
    FileUtils.ln_s( src,
                    dest,
                    force: force,
                    relative: relative,
                    target_directory: target_directory,
                    noop: noop,
                    verbose: verbose )
  end

  def self.makepath( list, mode: nil, noop: nil, verbose: nil )
    FileUtils.makepath( list, mode: mode, noop: noop, verbose: verbose )
  end

  def self.mkdir_p( list, mode: nil, noop: nil, verbose: nil )
    FileUtils.mkdir_p( list, mode: mode, noop: noop, verbose: verbose )
  end

  def self.mkdirs( list, mode: nil, noop: nil, verbose: nil )
    FileUtils.mkdirs( list, mode: mode, noop: noop, verbose: verbose )
  end

  def self.move( src, dest, force: nil, noop: nil, verbose: nil, secure: nil )
    FileUtils.move( src, dest, noop: noop, verbose: verbose, secure: secure )
  end

  def self.mv( src, dest, force: nil, noop: nil, verbose: nil, secure: nil )
    FileUtils.mv( src, dest, noop: noop, verbose: verbose, secure: secure )
  end

  def self.symlink( src, dest, force: nil, relative: false, target_directory: true, noop: nil, verbose: nil )
    FileUtils.symlink( src,
                       dest,
                       force: force,
                       relative: relative,
                       target_directory: target_directory,
                       noop: noop,
                       verbose: verbose )
  end

end
