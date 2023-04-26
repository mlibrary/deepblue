# frozen_string_literal: true
# hyrax-orcid

# Organise the data required to unpublish the work for each of the contributors, and create a job for each
module Hyrax
  module Orcid
    class UnpublishWorkDelegator
      include Hyrax::Orcid::ActiveJobType

      def initialize(work)
        @work = work
      end

      # If the work includes our default processable terms
      def perform
        Hyrax::Orcid::WorkOrcidExtractor.new(@work).extract.each { |orcid| delegate(orcid) }
      end

      protected

        # Find the identity and farm out the rest of the logic to a background worker
        def delegate(orcid_id)
          return if (identity = OrcidIdentity.find_by(orcid_id: orcid_id)).blank?

          Hyrax::Orcid::UnpublishWorkJob.send(active_job_type, @work, identity)
        end
    end
  end
end
