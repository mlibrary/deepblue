# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustFileSetList

  class Entry

    attr_reader :id, :name, :size, :split, :id_orig, :name_orig

    def initialize( id: nil, name: nil, size: nil )
      @id = id
      @name = name
      @size = size
      @split = false
      @id_orig = nil
      @name_orig = nil
    end

    def init_clone( entry )
      @id = entry.id
      @name = entry.name
      @size = entry.size
      @split = entry.split
      @id_orig = entry.id_orig
      @name_orig = entry.name_orig
    end

    def init_from_file_set( file_set )
      @id = file_set.id
      @name = file_set.label
      @size = ::Deepblue::MetadataHelper.file_set_file_size( file_set ).to_i
      @split = false
      @id_orig = nil
      @name_orig = nil
      return self
    end
    
    def init_from_split( file_set, name:, size: )
      @id = file_set.id
      @name = name
      @size = size
      @split = true
      @id_orig = file_set.id
      @name_orig = file_set.label
      return self
    end

    def init_split( id:, id_orig:, name:, name_orig:, size: )
      @id = id
      @name = name
      @size = size
      @split = true
      @id_orig = id_orig
      @name_orig = name_orig
      return self
    end

  end

  mattr_accessor :aptrust_file_list_set_debug_verbose, default: false

  attr_accessor :entries
  attr_accessor :file_sets
  attr_accessor :debug_verbose

  def initialize( debug_verbose: aptrust_file_list_set_debug_verbose )
    @entries = []
    @debug_verbose = debug_verbose
    @id_map = nil
  end

  def add( file_set: )
    if file_set.is_a?( Entry )
      e = file_set
    else
      e = Entry.new().init_from_file_set( file_set )
    end
    @entries << e
    return e
  end

  def add_all( file_sets: )
    file_sets.each { |fs| add( file_set: fs ) }
  end

  def add_from_file_set_list( file_set_list: )
    file_set_list.entries do |entry|
      # e = { id: entry.id, size: entry.size, name: entry.name }
      e = Entry.init_clone( entry )
      @entries << e
    end
    return self
  end

  def add_split( id:, id_orig:, name:, name_orig:, size: )
    @entries << Entry.new().init_split( id: id, id_orig: id_orig, name: name, name_orig: name_orig, size: size )
  end

  def clear
    @entries = []
  end

  def copy_file_sets_up_to( target_file_set_list: nil, max_total: )
    # puts "copy_file_sets_up_to self=#{self.pretty_inspect}"
    rv = target_file_set_list
    rv ||= ::Aptrust::AptrustFileSetList.new( debug_verbose: debug_verbose )
    total = rv.total_file_sets_size
    entries.each do |f|
      # puts "f=#{f.pretty_inspect}"
      sz = f.size
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
    f = entries.delete( f )
    return f
  end

  def delete_file_sets( file_set_list: )
    # puts "delete_file_sets self=#{self.pretty_inspect}"
    # puts "file_set_list=#{file_set_list.pretty_inspect}"
    file_set_list.entries.each { |f| delete_file_set( id: f.id ) }
    # puts "self=#{self.pretty_inspect}"
    return self
  end

  def drop( n )
    @entries = @entries.drop(n)
    return self
  end

  def drop_file_sets( file_set_list: )
    file_set_list.entries { |f| delete_file_set( id: f.id ) }
    return self
  end

  def empty?
    entries.empty?
  end

  def file_set_size( file_set: )
    sz = ::Deepblue::MetadataHelper.file_set_file_size( file_set )
    return sz.to_i
  end

  def find_file_set( id: )
    entries.each { |f| return f if f.id == id }
    return nil
  end

  def id_map()
    @id_map ||= id_map_init()
    @id_map
  end

  def id_map_init()
    map = {}
    entries.each { |f| map[f.id] = f }
    map
  end

  def include?( id: )
    id_map.has_key?( id )
  end

  def include_file_set?( id: )
    entries.each { |f| return true if f.id == id }
    return false
  end

  def list_file_sets
    rv = []
    entries.each { |f| rv << f.id }
    return rv
  end

  def size
    entries.size
  end

  def sort_by_name( ascending: true )
    if ascending
      entries.sort! { |a,b| a.name < b.name ? 0 : 1 }
    else
      entries.sort! { |a,b| a.name > b.name ? 0 : 1 }
    end
    return self
  end

  def sort_by_size( ascending: true )
    if ascending
      entries.sort! { |a,b| sort_by_size_entry( ascending: ascending, a: a, b: b ) }
    else
      entries.sort! { |a,b| sort_by_size_entry( ascending: ascending, a: a, b: b ) }
    end
    return self
  end

  def sort_by_size_entry( ascending:, a:, b: )
    if ascending
      rv = a.size < b.size ? 0 : 1
    else
      rv = a.size > b.size ? 0 : 1
    end
    # rv = a.name < b.name ? 0 : 1 if 0 == rv
    return rv
  end

  def total_file_sets_size
    total = 0
    entries.each { |f| total += f.size }
    return total
  end

  def total_file_sets_size_human_readable
    DeepblueHelper.human_readable_size( total_file_size )
  end

end
