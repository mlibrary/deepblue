# frozen_string_literal: true

module BrowseEverything
  module Driver
    # Class for instantiating authentication API Objects
    class AuthenticationFactory

      # begin monkey
      mattr_accessor :browse_everything_driver_authentication_factory_debug_verbose,
                     default: ::BrowseEverythingIntegrationService.browse_everything_driver_authentication_factory_debug_verbose
      # end monkey
      #
      # Constructor
      # @param klass [Class] the authentication object class
      # @param params [Array, Hash] the parameters for the authentication constructor
      def initialize(klass, *params)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "klass=#{klass}",
                                               "params=#{params}",
                                               "" ] if browse_everything_driver_authentication_factory_debug_verbose
        @klass = klass
        @params = params
      end

      # Constructs an authentication Object
      # @return [Object]
      def authenticate
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "@klass=#{@klass}",
                                               "@params=#{@params}",
                                               "" ] if browse_everything_driver_authentication_factory_debug_verbose
        @klass.new(*@params)
      end
    end
  end
end
