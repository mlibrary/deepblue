# frozen_string_literal: true
# hyrax-orcid

# This strategy exists so that the user doesn't need to remove the authorisation to prevent works being synced,
# or notifications being added to their account - which could be annoying - but still be able to have their
# personal/professional history shown on the public profile,
module Hyrax
  module Orcid
    module Strategy
      class Manual
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
          return nil
        end
      end
    end
  end
end
