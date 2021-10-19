# frozen_string_literal: true
module Hyrax
  module Doi
    module DoiFormBehavior
      extend ActiveSupport::Concern

      included do
        self.terms += [:doi]

        delegate :doi, to: :model
      end

      def secondary_terms
        super - [:doi]
      end
    end
  end
end
