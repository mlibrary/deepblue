# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Actors
    module Orcid
      class UnpublishWorkActor < ::Hyrax::Actors::AbstractActor
        include Hyrax::Orcid::ActiveJobType

        def destroy(env)
          unpublish_work(env)

          next_actor.destroy(env)
        end

        protected

          def unpublish_work(env)
            return unless enabled?

            Hyrax::Orcid::UnpublishWorkDelegatorJob.send(active_job_type, env.curation_concern)
          end

        private

          def enabled?
            Flipflop.enabled?(:hyrax_orcid)
          end
      end
    end
  end
end
