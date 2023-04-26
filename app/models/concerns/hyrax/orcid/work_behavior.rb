# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module WorkBehavior

      extend ActiveSupport::Concern

      included do
        class_attribute :json_fields
        # FIXME: OrcidHelper.json_fields should be a configuration option
        self.json_fields = OrcidHelper.json_fields
      end
    end
  end
end
