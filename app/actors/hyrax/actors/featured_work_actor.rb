
module Hyrax
  module Actors
    # Removes featured works if the work is deleted or becomes private
    class FeaturedWorkActor < Hyrax::Actors::AbstractActor

      mattr_accessor :featured_work_actor_debug_verbose,
                     default: ::DeepBlueDocs::Application.config.featured_work_actor_debug_verbose

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        cleanup_featured_works(env.curation_concern)
        next_actor.destroy(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        check_featureability(env.curation_concern)
        next_actor.update(env)
      end

      private

        def cleanup_featured_works(curation_concern)
          # begin monkey
          return unless curation_concern
          # end monkey
          FeaturedWork.where(work_id: curation_concern.id).destroy_all
        end

        def check_featureability(curation_concern)
          # begin monkey
          return unless curation_concern
          # end monkey
          return unless curation_concern.private?
          cleanup_featured_works(curation_concern)
        end
    end
  end
end
