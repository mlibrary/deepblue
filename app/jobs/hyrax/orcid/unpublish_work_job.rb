# frozen_string_literal: true
# hyrax-orcid

# Each contributor to a work will have their own job created that runs the unpublish service
module Hyrax
  module Orcid
    class UnpublishWorkJob < ApplicationJob
      queue_as Hyrax.config.ingest_queue_name

      def perform(work, identity)
        debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_jobs_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "Flipflop.hyrax_orcid?=#{Flipflop.hyrax_orcid?}",
                                               "work.id=#{work.id}",
                                               "identity=#{identity}",
                                               "" ] if debug_verbose
        return unless Flipflop.hyrax_orcid? # TODO: added, is this correct?
        Hyrax::Orcid::Work::PublisherService.new(work, identity).unpublish
      end
    end
  end
end
