# frozen_string_literal: true

module Hyrax
  module Actors

    class AbstractEventActor < AbstractActor

      protected

        def env_attributes_by_key( env:, key: )
          env.attributes.values_at( key )
        end

        def attributes_blank?( attributes )
          return true if attributes.blank?
          return true if [nil] == attributes
          false
        end

    end

  end
end
