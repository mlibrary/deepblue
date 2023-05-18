# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    class PerformIdentityStrategyJob < ApplicationJob
      queue_as Hyrax.config.ingest_queue_name

      def perform(work, identity)
        debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_jobs_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "Flipflop.hyrax_orcid?=#{Flipflop.hyrax_orcid?}",
                                               "work.id=#{work.id}",
                                               "identity=#{identity}",
                                               "" ] if debug_verbose
        return unless Flipflop.hyrax_orcid?
        "Hyrax::Orcid::Strategy::#{identity.work_sync_preference.classify}".constantize.new(work, identity).perform
      end
    end
  end
end
