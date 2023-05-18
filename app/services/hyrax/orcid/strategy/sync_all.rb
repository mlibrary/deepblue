# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Strategy
      class SyncAll
        def initialize(work, identity)
          @work = work
          @identity = identity
        end

        def perform
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_strategy_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@work.id=#{@work.id}",
                                                 "@identity=#{@identity}",
                                                 "" ] if debug_verbose
          Hyrax::Orcid::Work::PublisherService.new(@work, @identity).publish
        end
      end
    end
  end
end
