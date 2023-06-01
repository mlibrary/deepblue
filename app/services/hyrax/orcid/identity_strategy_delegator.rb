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
        debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_jobs_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "Flipflop.hyrax_orcid?=#{Flipflop.hyrax_orcid?}",
                                               "@work.id=#{@work.id}",
                                               "" ] if debug_verbose
        return unless Flipflop.hyrax_orcid?

        orcids = Hyrax::Orcid::WorkOrcidExtractor.new(@work).extract
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "Flipflop.hyrax_orcid?=#{Flipflop.hyrax_orcid?}",
                                               "orcids=#{orcids}",
                                               "" ] if debug_verbose

        orcids.each { |orcid| perform_user_strategy(orcid) }
      end

      protected

        # Find the identity and farm out the rest of the logic to a background worker
        def perform_user_strategy(orcid_id)
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_jobs_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "orcid_id=#{orcid_id}",
                                                 "" ] if debug_verbose
          identity = OrcidIdentity.find_by(orcid_id: orcid_id)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "identity=#{identity}",
                                                 "" ] if debug_verbose
          return if identity.blank?
          # return if (identity = OrcidIdentity.find_by(orcid_id: orcid_id)).blank?

          Hyrax::Orcid::PerformIdentityStrategyJob.send(active_job_type, @work, identity)
        end

        def validate!
          raise ArgumentError, "A work is required" unless @work.is_a?(ActiveFedora::Base)
        end
    end
  end
end
