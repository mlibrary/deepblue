# frozen_string_literal: true

module Hyrax
  module Actors

    class DataSetActor < Hyrax::Actors::BaseActor

      # Cast any singular values from the form to multiple values for persistence
      def clean_attributes(attributes)
        attributes[:rights_license] = Array(attributes[:rights_license]) if attributes.key? :rights_license
        super( attributes )
      end

    end

  end
end
