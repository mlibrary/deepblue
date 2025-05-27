# frozen_string_literal: true
#
require "securerandom"

module Deepblue

  module CacheService

    def self.is_cache_available?
      test_value = SecureRandom.hex
      cache_key = "cache-check-#{Socket.gethostname}"
      Rails.cache.write(cache_key, test_value)
      rv = test_value == Rails.cache.read(cache_key)
      if rv
        # puts "Able to read and write via #{humanize_cache_store_name}"
      else
        # puts "Value read from the cache does not match the value written"
      end
      return rv
    rescue => error
      # puts "Connection failure: #{error}"
      false
    end

    def self.init_cache_available
      # puts "Rails.env.test?=#{Rails.env.test?}"
      return false if Rails.env.test?
      return false unless Rails.env.production?
      is_cache_available?
    end

    def self.cache_available?
      @@cache_available ||= init_cache_available
    end

    mattr_accessor :deepblue_cache_service_debug_verbose, default: false

    def self.event_attributes_cache_exist?( event:, id:, behavior: nil )
      key = event_attributes_cache_key( event: event, id: id, behavior: behavior )
      rv = Rails.cache.exist?( key )
      rv
    end

    def self.event_attributes_cache_fetch( event:, id:, behavior: nil )
      key = event_attributes_cache_key( event: event, id: id, behavior: behavior )
      rv = Rails.cache.fetch( key )
      rv
    end

    def self.event_attributes_cache_key( event:, id:, behavior: nil )
      return "#{id}.#{event}" if behavior.blank?
      "#{id}.#{event}.#{behavior}"
    end

    def self.event_attributes_cache_write( event:, id:, attributes: DateTime.now, behavior: nil )
      key = event_attributes_cache_key( event: event, id: id, behavior: behavior )
      Rails.cache.write( key, attributes )
    end

    def self.humanize_cache_store_name
      name = if Rails.application.config.cache_store.is_a? Array
               Rails.application.config.cache_store[0]
             else
               Rails.application.config.cache_store
             end
      name.to_s.humanize
    end

    def self.var_cache_exist?( klass:, var: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "klass=#{klass}",
                                             "var=#{var}",
                                             "" ] if deepblue_cache_service_debug_verbose
      key = var_cache_key( klass: klass, var: var )
      rv = Rails.cache.exist?( key )
      rv
    end

    def self.var_cache_fetch( klass:, var:, default_value: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "klass=#{klass}",
                                             "var=#{var}",
                                             "default_value=#{default_value}",
                                             "" ] if deepblue_cache_service_debug_verbose
      key = var_cache_key( klass: klass, var: var )
      rv = Rails.cache.fetch( key )
      return default_value if rv.nil?
      rv
    end

    def self.var_cache_key( klass:, var: )
      return "DBD.#{klass.name}.#{var.to_s}"
    end

    def self.var_cache_write(  klass:, var:, value: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "klass=#{klass}",
                                             "var=#{var}",
                                             "value=#{value}",
                                             "" ] if deepblue_cache_service_debug_verbose
      key = var_cache_key( klass: klass, var: var )
      Rails.cache.write( key, value )
    end

  end

end
