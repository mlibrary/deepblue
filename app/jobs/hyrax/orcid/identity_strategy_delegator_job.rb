# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    class IdentityStrategyDelegatorJob < ApplicationJob
      queue_as Hyrax.config.ingest_queue_name
      discard_on ArgumentError

      def perform(work)
        return unless Flipflop.enabled?(:hyrax_orcid)

        Hyrax::Orcid::IdentityStrategyDelegator.new(work).perform
      end
    end
  end
end
