# frozen_string_literal: true

module Deepblue

  module InterpolationHelper

    mattr_accessor :interpolation_helper_debug_verbose,
                   default: ::Deepblue::WorkViewContentService.interpolation_helper_debug_verbose
    mattr_accessor :interpolation_pattern,
                   default: ::Deepblue::WorkViewContentService.static_content_interpolation_pattern

    def self.new_interporlation_values
      values = {}
      values[:contact_us_at] = EmailHelper.contact_us_at
      values[:host_url] = Rails.configuration.hostname
      # TODO: fix these (by adding values to config)
      values[:example_collection_id] = "c1234567"
      values[:example_data_set_id] = "d1234567"
      values[:example_file_set_id] = "f1234567"
      return values
    end

    # Interpolates values into a given target.
    #
    #   if the given target is a string then:
    #   method interpolates "file %{file} opened by %%{user}", :file => 'test.txt', :user => 'Mr. X'
    #   # => "file test.txt opened by %{user}"
    #
    #   if the given target is an array then:
    #   each element of the array is recursively interpolated (until it finds a string)
    #   method interpolates ["yes, %{user}", ["maybe no, %{user}, "no, %{user}"]], :user => "bartuz"
    #   # => "["yes, bartuz",["maybe no, bartuz", "no, bartuz"]]"
    #
    def self.interpolate( target:, values: {} )
      return target if target.blank?
      return target if values.empty?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "values=#{values}",
                                             "" ] if interpolation_helper_debug_verbose
      case target
      when ::String then interpolate_string(target, values)
      when ::Array then target.map { |element| interpolate( target: element, values: values ) }
      else
        target
      end
    end

    private

      # Return String or raises MissingInterpolationArgument exception.
      # Missing argument's logic is handled by I18n.config.missing_interpolation_argument_handler.
      def self.interpolate_string( string, values )
        raise I18n::ReservedInterpolationKey.new($1.to_sym, string) if string =~ I18n::RESERVED_KEYS_PATTERN
        raise ArgumentError.new('Interpolation values must be a Hash.') unless values.kind_of?(Hash)
        interpolate_hash( string, values )
      end

      def self.interpolate_hash( string, values )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if interpolation_helper_debug_verbose
        string.gsub( interpolation_pattern ) do |match|
          if match == '%%'
            '%'
          else
            key = ($1 || $2 || match.tr("%{}", "")).to_sym
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "key=#{key}",
                                                   "" ] if interpolation_helper_debug_verbose
            value = if values.key?(key)
                      values[key]
                    else
                      # TODO:
                      # config.missing_interpolation_argument_handler.call(key, values, string)
                    end
            value = value.call(values) if value.respond_to?(:call)
            $3 ? sprintf("%#{$3}", value) : value
          end
        end
      end

  end

end
