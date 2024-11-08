# frozen_string_literal: true

class ::Deepblue::OptionsMap
  # include Enumerable # TODO

  def self.options_map( map: nil, dup: false )
    return map if !dup && map.is_a?( ::Deepblue::OptionsMap )
    ::Deepblue::OptionsMap.new( map: map )
  end

  attr_accessor :auto_add_defaults
  attr_reader   :map

  delegate :delete, :has_key?, :include?, :key?, :keys, :member?, to: :map

  def initialize( map: nil, auto_add_defaults: true )
    @auto_add_defaults = auto_add_defaults
    if map.nil?
      @map = {}.with_indifferent_access
    elsif map.instance_of? ::Deepblue::OptionsMap
      @map = map.map.dup
    elsif map.instance_of? ::ActiveSupport::HashWithIndifferentAccess
      @map = map.dup
    elsif map.instance_of? Hash
      @map = map.with_indifferent_access
    else
      raise ArgumentError "expected map: to be instance of OptionsMap, Hash, or ActiveSupport::HashWithIndifferentAccess"
    end
  end

  def []( key )
    @map[key]
  end

  def []=( key, value )
    @map[key] = value
  end

  def add( key, value: )
    @map[key] = value
    self
  end

  def append( key, value: )
    new_value =  @map[key]
    new_value = Array( new_value )
    new_value << value
    @map[key] = new_value
  end

  def error?
    option_value( :error, default_value: false )
  end

  def merge( *other_maps )
    # TODO: test
    maps = other_maps.map { |map| map.is_a?( ::Deepblue::OptionsMap ) ? map.map : map }
    OptionsMap.new( map: @map.merge( maps ), auto_add_defaults: @auto_add_defaults )
  end


  def merge!( *other_maps )
    # TODO: test
    maps = other_maps.map { |map| map.is_a?( ::Deepblue::OptionsMap ) ? map.map : map }
    @map.merge( maps )
  end

  def option( key )
    @map.key?( key )
  end
  alias :option? :option

  def option_value( key, default_value: nil, msg_handler: nil )
    if @map.has_key?( key )
      msg_handler.msg_debug "option #{key} is #{@map[key]}" if msg_handler.present?
      return @map[key]
    end


    msg_handler.msg_debug "option #{key} is default_value #{default_value}" if msg_handler.present?
    @map[ key ] = default_value if auto_add_defaults
    return default_value

  end
  alias :value :option_value

end
