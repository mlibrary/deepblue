# frozen_string_literal: true

module Hyrax
  module Actors

    class BeforeModelActor < AbstractEventActor

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create( env )
        log_before_event( env: env, event: :create )
        next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy( env )
        log_before_event( env: env, event: :destroy )
        next_actor.destroy(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update( env )
        log_before_event( env: env, event: :update )
        next_actor.update(env)
      end

      protected

        def log_before_event( env:, event: )
          actor = next_actor
          Deepblue::LoggingHelper.bold_debug "BeforeModelActor.#{event}: env.curation_concern.class=#{env.curation_concern.class.name} next_actor = #{actor.class.name}"
        end

      # def model_actor(env)
      #   actor_identifier = env.curation_concern.class
      #   klass = "Hyrax::Actors::#{actor_identifier}Actor".constantize
      #   klass.new(next_actor)
      # end

    end

  end
end
