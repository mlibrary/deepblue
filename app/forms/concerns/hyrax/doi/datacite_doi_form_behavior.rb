# frozen_string_literal: true
module Hyrax
  module Doi
    module DataCiteDoiFormBehavior
      extend ActiveSupport::Concern

      included do
        self.terms += [:doi_status_when_public]

        delegate :doi_status_when_public, to: :model
      end

      def secondary_terms
        super - [:doi_status_when_public]
      end
    end
  end
end
