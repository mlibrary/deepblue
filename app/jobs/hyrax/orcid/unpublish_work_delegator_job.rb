# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    class UnpublishWorkDelegatorJob < ApplicationJob
      queue_as Hyrax.config.ingest_queue_name

      def perform(work)
        debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_jobs_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "Flipflop.hyrax_orcid?=#{Flipflop.hyrax_orcid?}",
                                               "work.id=#{work.id}",
                                               "" ] if debug_verbose
        return unless Flipflop.hyrax_orcid?
        Hyrax::Orcid::UnpublishWorkDelegator.new(work).perform
      end
    end
  end
end
