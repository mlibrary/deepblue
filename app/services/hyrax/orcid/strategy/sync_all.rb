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
          Hyrax::Orcid::Work::PublisherService.new(@work, @identity).publish
        end
      end
    end
  end
end
