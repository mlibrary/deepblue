
# monkey override actionpack lib/action_controller/metal/parameters_track_errors.rb

module ActionController

  class ParametersTrackErrors < Parameters

    PARAMETERS_TRACK_ERRORS_VERBOSE = false

    attr_accessor :errors

    def initialize( parameters = {} )
      super( parameters.is_a?( Parameters ) ? {} : parameters )
      if parameters.is_a? Parameters
        @parameters = parameters.instance_variable_get(:@parameters).deep_dup
        @permitted = parameters.instance_variable_get(:@permitted)
      end
      @errors = []
    end

    def deep_dup
      params = super
      params.errors = errors.dup
      return params
    end

    def permit(*filters)
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ] if PARAMETERS_TRACK_ERRORS_VERBOSE
      params = super( *filters )
      # params = permit_monkey( *filters )
      params.errors = errors.dup
      return params
    end

    def permit_monkey(*filters)
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ] if PARAMETERS_TRACK_ERRORS_VERBOSE
      params = self.class.new

      filters.flatten.each do |filter|
        case filter
        when Symbol, String
          permitted_scalar_filter(params, filter)
        when Hash
          hash_filter(params, filter)
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "params.class.name=#{params.class.name}",
                                             "params.keys=#{params.keys}",
                                             "" ] if PARAMETERS_TRACK_ERRORS_VERBOSE

      unpermitted_parameters!(params) if self.class.action_on_unpermitted_parameters

      params.permit!
    end

    def unpermitted_parameters!( params )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "" ] if PARAMETERS_TRACK_ERRORS_VERBOSE
      unpermitted_keys = unpermitted_keys( params )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "unpermitted_keys=#{unpermitted_keys}",
                                             "" ] if PARAMETERS_TRACK_ERRORS_VERBOSE
      if unpermitted_keys.any?
        @errors << "unpermitted_keys: #{unpermitted_keys}"
      end
      super( params )
    end

    def unpermitted_keys(params)
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "keys=#{keys}",
                                             "keys=#{params.keys}",
                                             "always_permitted_parameters=#{always_permitted_parameters}",
                                             "" ] if PARAMETERS_TRACK_ERRORS_VERBOSE
      keys - params.keys - always_permitted_parameters
    end

    private

      def convert_value_to_parameters(value)
        rv = super( value )
        case value
        when Hash
          rv.errors = errors.dup
        end
        return rv
      end

      def new_instance_with_inherited_permitted_status(hash)
        self.class.new(hash).tap do |new_instance|
          new_instance.permitted = @permitted
          new_instance.errors = @errors.dup
        end
      end

      def permit_any_in_parameters(params)
        rv = super(params)
        rv.errors = errors.dup
        return rv
      end

  end

end
