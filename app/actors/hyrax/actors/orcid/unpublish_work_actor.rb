# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Actors
    module Orcid
      class UnpublishWorkActor < ::Hyrax::Actors::AbstractActor
        include Hyrax::Orcid::ActiveJobType

        def destroy(env)
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_actors_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "" ] if debug_verbose
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
            Flipflop.hyrax_orcid?
          end
      end
    end
  end
end
