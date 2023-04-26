# frozen_string_literal: true
# hyrax-orcid

# Each contributor to a work will have their own job created that runs the unpublish service
module Hyrax
  module Orcid
    class UnpublishWorkJob < ApplicationJob
      queue_as Hyrax.config.ingest_queue_name

      def perform(work, identity)
        Hyrax::Orcid::Work::PublisherService.new(work, identity).unpublish
      end
    end
  end
end
