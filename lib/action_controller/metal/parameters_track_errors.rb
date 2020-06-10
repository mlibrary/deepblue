
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
      params = super( *filters )
      params.errors = errors.dup
      return params
    end

    def unpermitted_parameters!( params )
      unpermitted_keys = unpermitted_keys( params )
      if unpermitted_keys.any?
        @errors << "unpermitted_keys: #{unpermitted_keys}"
      end
      super( params )
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
