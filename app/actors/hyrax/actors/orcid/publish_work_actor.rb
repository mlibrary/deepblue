# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Actors
    module Orcid
      class PublishWorkActor < ::Hyrax::Actors::AbstractActor
        include Hyrax::Orcid::ActiveJobType

        def create(env)
          delegate_work_strategy(env)

          next_actor.create(env)
        end

        def update(env)
          delegate_work_strategy(env)

          next_actor.update(env)
        end

        protected

          def delegate_work_strategy(env)
            return unless enabled? && visible?(env)

            Hyrax::Orcid::IdentityStrategyDelegatorJob.send(active_job_type, env.curation_concern)
          end

        private

          def visible?(env)
            env.curation_concern.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          end

          def enabled?
            Flipflop.hyrax_orcid?
          end
      end
    end
  end
end
