# frozen_string_literal: true
# hyrax-orcid

# Take a work, extract its orcid ids, and for each orcid identity that is found
# create a seperate job to process the users identity sync strategy.
module Hyrax
  module Orcid
    class IdentityStrategyDelegator
      include Hyrax::Orcid::ActiveJobType

      def initialize(work)
        @work = work

        validate!
      end

      # If the work includes our default processable terms
      def perform
        return unless Flipflop.enabled?(:hyrax_orcid)

        orcids = Hyrax::Orcid::WorkOrcidExtractor.new(@work).extract

        orcids.each { |orcid| perform_user_strategy(orcid) }
      end

      protected

        # Find the identity and farm out the rest of the logic to a background worker
        def perform_user_strategy(orcid_id)
          return if (identity = OrcidIdentity.find_by(orcid_id: orcid_id)).blank?

          Hyrax::Orcid::PerformIdentityStrategyJob.send(active_job_type, @work, identity)
        end

        def validate!
          raise ArgumentError, "A work is required" unless @work.is_a?(ActiveFedora::Base)
        end
    end
  end
end
