# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustFileList

  mattr_accessor :aptrust_file_list_debug_verbose, default: false

  def self.from_dir( dir:, debug_verbose: aptrust_file_list_debug_verbose )
    file_list = ::Aptrust::AptrustFileList.new( debug_verbose: debug_verbose )
    file_list.add_from( dir: dir )
    return file_list
  end

  attr_accessor :files
  attr_accessor :debug_verbose

  def initialize( debug_verbose: aptrust_file_list_debug_verbose )
    @files = []
    @debug_verbose = debug_verbose
  end

  def add( file: )
    sz = File.size file
    f = { file: file, size: sz, name: File.basename( file ) }
    files << f
    return f
  end

  def add_from( dir: )
    list = ::Deepblue::DiskUtilitiesHelper.files_in_dir( dir, dotmatch: true, msg_handler: ::Aptrust::NULL_MSG_HANDLER )
    list.each { |f| add( file: f ) }
    return self
  end

  def add_from_file_list( file_list: )
    file_list.each { |f| add( file: f[:file] ) }
    return self
  end

  def clear
    @files = []
  end

  def delete_file( file: )
    f = find_file( file: file )
    return nil if f.nil?
    files.delete( f )
    return f
  end

  def delete_files( files: )
    files.each { |file| delete_file( file: file ) }
    return self
  end

  def drop( n )
    @files = @files.drop(n)
    return self
  end

  def drop_files( file_list: )
    file_list.each { |f| delete_file( file: f[:file] ) }
    return self
  end

  def empty?
    files.empty?
  end

  def file_list_up_to( file_list: nil, max_total: )
    rv = file_list
    rv ||= ::Aptrust::AptrustFileList.new( debug_verbose: debug_verbose )
    total = rv.total_file_size
    files.each do |f|
      sz = f[:size]
      return rv if (total + sz) > max_total
      total += sz
      rv.add( file: f[:file] )
    end
    return rv
  end

  def find_file( file: )
    files.each { |f| return f if f[:file] == file }
    return nil
  end

  def include_file?( file: )
    files.each { |f| return true if f[:file] == file }
    return false
  end

  def list_files
    rv = []
    files.each { |f| rv << f[:file] }
    return rv
  end

  def list_files_up_to( max_total: )
    rv = []
    total = 0
    files.each do |f|
      sz = f[:size]
      return rv if (total + sz) > max_total
      total += sz
      rv << f[:file]
    end
    return rv
  end

  def size
    files.size
  end

  def sort_by_name( ascending: true )
    if ascending
      files.sort! { |a,b| a[:name] < b[:name] ? 0 : 1 }
    else
      files.sort! { |a,b| a[:name] > b[:name] ? 0 : 1 }
    end
    return self
  end

  def sort_by_size( ascending: true )
    if ascending
      files.sort! { |a,b| sort_by_size_entry( ascending: ascending, a: a, b: b ) }
    else
      files.sort! { |a,b| sort_by_size_entry( ascending: ascending, a: a, b: b ) }
    end
    return self
  end

  def sort_by_size_entry( ascending:, a:, b: )
    if ascending
      rv = a[:size] < b[:size] ? 0 : 1
    else
      rv = a[:size] > b[:size] ? 0 : 1
    end
    # rv = a[:name] < b[:name] ? 0 : 1 if 0 == rv
    return rv
  end

  def total_file_size
    total = 0
    files.each { |f| total += f[:size] }
    return total
  end

  def total_file_size_human_readable
    DeepblueHelper.human_readable_size( total_file_size )
  end

end
