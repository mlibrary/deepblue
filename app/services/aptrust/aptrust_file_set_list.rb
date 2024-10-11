# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustFileSetList

  mattr_accessor :aptrust_file_list_set_debug_verbose, default: false

  attr_accessor :file_sets
  attr_accessor :debug_verbose

  def initialize( debug_verbose: aptrust_file_list_set_debug_verbose )
    @file_sets = []
    @debug_verbose = debug_verbose
    @id_map = nil
  end

  def add( file_set: )
    if file_set.is_a?( Hash )
      f = file_set
    else
      f = { id: file_set.id, size: file_set_size( file_set: file_set ), name: file_set.label }
    end
    @file_sets << f
    return f
  end

  def add_all( file_sets: )
    file_sets.each { |fs| add( file_set: fs ) }
  end

  def add_from_file_set_list( file_set_list: )
    file_set_list.file_sets do |fs|
      f = { id: fs.id, size: fs.size, name: fs.name }
      @file_sets << f
    end
    return self
  end

  def clear
    @file_sets = []
  end

  def copy_file_sets_up_to( target_file_set_list: nil, max_total: )
    # puts "copy_file_sets_up_to self=#{self.pretty_inspect}"
    rv = target_file_set_list
    rv ||= ::Aptrust::AptrustFileSetList.new( debug_verbose: debug_verbose )
    total = rv.total_file_sets_size
    file_sets.each do |f|
      # puts "f=#{f.pretty_inspect}"
      sz = f[:size]
      if (total + sz) > max_total
        # puts "rv=#{rv.pretty_inspect}"
        return rv
      end
      total += sz
      rv.add( file_set: f )
    end
    # puts "rv=#{ rv.pretty_inspect}"
    return rv
  end

  def delete_file_set( id: )
    f = find_file_set( id: id )
    return nil if f.nil?
    f = file_sets.delete( f )
    return f
  end

  def delete_file_sets( file_set_list: )
    # puts "delete_file_sets self=#{self.pretty_inspect}"
    # puts "file_set_list=#{file_set_list.pretty_inspect}"
    file_set_list.file_sets.each { |f| delete_file_set( id: f[:id] ) }
    # puts "self=#{self.pretty_inspect}"
    return self
  end

  def drop( n )
    @file_sets = @file_sets.drop(n)
    return self
  end

  def drop_file_sets( file_set_list: )
    file_set_list.file_sets { |f| delete_file_set( id: f[:id] ) }
    return self
  end

  def empty?
    file_sets.empty?
  end

  def file_set_size( file_set: )
    sz = ::Deepblue::MetadataHelper.file_set_file_size( file_set )
    return sz.to_i
  end

  def find_file_set( id: )
    file_sets.each { |f| return f if f[:id] == id }
    return nil
  end

  def id_map()
    @id_map ||= id_map_init()
    @id_map
  end

  def id_map_init()
    map = {}
    file_sets.each { |f| map[f.id] = f }
    map
  end

  def include?( id: )
    id_map.has_key?( id )
  end

  def include_file_set?( id: )
    file_sets.each { |f| return true if f[:id] == id }
    return false
  end

  def list_file_sets
    rv = []
    file_sets.each { |f| rv << f[:id] }
    return rv
  end

  def size
    file_sets.size
  end

  def sort_by_label( ascending: true )
    if ascending
      file_sets.sort! { |a,b| a[:label] < b[:label] ? 0 : 1 }
    else
      file_sets.sort! { |a,b| a[:label] > b[:label] ? 0 : 1 }
    end
    return self
  end

  def sort_by_size( ascending: true )
    if ascending
      file_sets.sort! { |a,b| sort_by_size_entry( ascending: ascending, a: a, b: b ) }
    else
      file_sets.sort! { |a,b| sort_by_size_entry( ascending: ascending, a: a, b: b ) }
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

  def total_file_sets_size
    total = 0
    file_sets.each { |f| total += f[:size] }
    return total
  end

  def total_file_sets_size_human_readable
    DeepblueHelper.human_readable_size( total_file_size )
  end

end
