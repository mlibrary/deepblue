# frozen_string_literal: true

module Hyrax
  module Actors
    # Responsible for removing trophies related to the given curation concern.
    class CleanupTrophiesActor < Hyrax::Actors::AbstractActor

      mattr_accessor :cleanup_trophies_actor_debug_verbose,
                     default: Rails.configuration.cleanup_trophies_actor_debug_verbose

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        cleanup_trophies(env)
        next_actor.destroy(env)
      end

      private

      def cleanup_trophies(env)
        # begin monkey
        return unless env.curation_concern
        # end monkey
        Trophy.where(work_id: env.curation_concern.id).destroy_all
      end
    end
  end
end
