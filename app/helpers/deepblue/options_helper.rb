# frozen_string_literal: true

require_relative './options_map'

module Deepblue

  module OptionsHelper

    def self.error?( options )
      value( options, key: 'error', default_value: false )
    end

    def self.from_args( *args )
      options = {}
      args.each { |key,value| options[key.to_s] = value }
      options.with_indifferent_access
    end

    def self.options_map( map: nil, dup: false )
      ::Deepblue::OptionsMap.options_map( map: map, dup: dup )
    end

    def self.options_map_from_args( *args )
      map = from_args( args )
      ::Deepblue::OptionsMap.new( map: map )
    end

    def self.options_map_parse( options_str )
      map = parse( options_str )
      ::Deepblue::OptionsMap.new( map: map )
    end

    def self.parse( options_str )
      return options_str.with_indifferent_access if options_str.is_a? Hash
      return options_str if options_str.is_a? ActiveSupport::HashWithIndifferentAccess
      return {}.with_indifferent_access if options_str.blank?
      options = ActiveSupport::JSON.decode options_str
      return options.with_indifferent_access
    rescue ActiveSupport::JSON.parse_error => e
      return { 'error': e, 'options_str': options_str }.with_indifferent_access
    end

    def self.value( options, key:, default_value: nil, msg_handler: nil )
      return options.options_value( key, default_value: default_value, msg_handler: msg_handler ) if options.is_a? ::Deepblue::OptionsMap
      return default_value if options.blank?
      return default_value unless options.key? key
      msg_handler.msg_debug "set key #{key} to #{options[key]}" if msg_handler.present?
      return options[key]
    end

  end

end
