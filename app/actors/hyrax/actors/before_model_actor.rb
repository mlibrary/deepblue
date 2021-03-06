# frozen_string_literal: true

module Hyrax
  module Actors

    class BeforeModelActor < AbstractEventActor

      BEFORE_MODEL_ACTOR_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.before_model_actor_debug_verbose

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create( env )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env=#{env}",
                                               "" ] if BEFORE_MODEL_ACTOR_DEBUG_VERBOSE
        env.log_event( next_actor: next_actor ) if env.respond_to? :log_event
        next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy( env )
        env.log_event( next_actor: next_actor )
        next_actor.destroy(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update( env )
        env.log_event( next_actor: next_actor )
        next_actor.update(env)
      end

      protected

        # def log_before_event( env:, event: )
        #   actor = next_actor
        #   Deepblue::LoggingHelper.bold_debug "BeforeModelActor.#{event}: env.curation_concern.class=#{env.curation_concern.class.name} next_actor = #{actor.class.name}"
        # end

      # def model_actor(env)
      #   actor_identifier = env.curation_concern.class
      #   klass = "Hyrax::Actors::#{actor_identifier}Actor".constantize
      #   klass.new(next_actor)
      # end

    end

  end
end
