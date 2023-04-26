# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module ActiveJobType
      extend ActiveSupport::Concern

      def active_job_type
        ::Hyrax::OrcidIntegrationService.active_job_type
      end
    end
  end
end
