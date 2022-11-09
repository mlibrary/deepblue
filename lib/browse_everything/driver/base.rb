# frozen_string_literal: true

module BrowseEverything
  module Driver
    # Abstract class for provider classes
    class Base
      include BrowseEverything::Engine.routes.url_helpers

      # begin monkey
      mattr_accessor :browse_everything_driver_base_debug_verbose,
                     default: ::BrowseEverythingIntegrationService.browse_everything_driver_base_debug_verbose
      mattr_accessor :browse_everything_driver_base2_debug_verbose,
                     default: ::BrowseEverythingIntegrationService.browse_everything_driver_base2_debug_verbose
      # end monkey

      # Provide accessor and mutator methods for @token and @code
      attr_accessor :token, :code

      # Integrate sorting lambdas for configuration using initializers
      class << self
        attr_accessor :sorter

        # Provide a default sorting lambda
        # @return [Proc]
        def default_sorter
          lambda { |files|
            files.sort do |a, b|
              if b.container?
                a.container? ? a.name.downcase <=> b.name.downcase : 1
              else
                a.container? ? -1 : a.name.downcase <=> b.name.downcase
              end
            end
          }
        end

        # Set the sorter lambda (or proc) for all subclasses
        # (see Class.inherited)
        # @param subclass [Class] the class inheriting from BrowseEverything::Driver::Base
        def inherited(subclass)
          subclass.sorter = sorter
        end
      end

      # Constructor
      # @param config_values [Hash] configuration for the driver
      def initialize(config_values)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "config_values=#{::Deepblue::LoggingHelper.mask(config_values,
                                                                             keys: ['client_secret'] )}",
                                               "" ] if browse_everything_driver_base2_debug_verbose
        @config = config_values
        # @config = ActiveSupport::HashWithIndifferentAccess.new(@config) if @config.is_a? Hash
        @sorter = self.class.sorter || self.class.default_sorter
        validate_config
      end

      # Ensure that the configuration Hash has indifferent access
      # @return [ActiveSupport::HashWithIndifferentAccess]
      def config
        @config = ActiveSupport::HashWithIndifferentAccess.new(@config) if @config.is_a? Hash
        @config
      end

      # Abstract method
      def validate_config
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if browse_everything_driver_base_debug_verbose
      end

      # Generate the key for the driver
      # @return [String]
      def key
        self.class.name.split(/::/).last.underscore
      end

      # Generate the icon markup for the driver
      # @return [String]
      def icon
        'unchecked'
      end

      # Generate the name for the driver
      # @return [String]
      def name
        @name ||= (@config[:name] || self.class.name.split(/::/).last.titleize)
      end

      # Abstract method
      def contents(*_args)
        []
      end

      # Generate the link for a resource at a given path
      # @param path [String] the path to the resource
      # @return [Array<String, Hash>]
      def link_for(path)
        [path, { file_name: File.basename(path) }]
      end

      # Abstract method
      def authorized?
        false
      end

      # Abstract method
      def auth_link(*_args)
        []
      end

      # Abstract method
      def connect(*_args)
        nil
      end

      private

      # Generate the options for the Rails URL generation for API callbacks
      # remove the script_name parameter from the url_options since that is causing issues
      #   with the route not containing the engine path in rails 4.2.0
      # @return [Hash]
      def callback_options
        options = config.to_hash
        options.deep_symbolize_keys!
        options[:url_options].reject { |k, _v| k == :script_name }
      end

      # Generate the URL for the API callback
      # @return [String]
      def callback
        # connector_response_url(callback_options)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "url_options=#{url_options}",
                                               "method(:connector_response_url).source_location=#{method(:connector_response_url).source_location}",
                                               "" ] if browse_everything_driver_base_debug_verbose
        rv = connector_response_url(**url_options)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "callback response rv=#{rv}",
                                               "" ] if browse_everything_driver_base_debug_verbose
        # Unfortunately, the connector_response_url does not return with /data as part of its path
        rv = rv.gsub( '/browse', '/data/browse' )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "callback response rv=#{rv}",
                                               "" ] if browse_everything_driver_base_debug_verbose
        return rv
      end
    end
  end
end
