# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    class PerformIdentityStrategyJob < ApplicationJob
      queue_as Hyrax.config.ingest_queue_name

      def perform(work, identity)
        return unless Flipflop.hyrax_orcid?

        "Hyrax::Orcid::Strategy::#{identity.work_sync_preference.classify}".constantize.new(work, identity).perform
      end
    end
  end
end
