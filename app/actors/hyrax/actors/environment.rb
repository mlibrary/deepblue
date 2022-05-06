# frozen_string_literal: true

require_relative './environment_attributes'

module Hyrax

  module Actors

    class Environment

      # @param [ActiveFedora::Base] curation_concern work to operate on
      # @param [Ability] current_ability the authorizations of the acting user
      # @param [ActionController::Parameters] attributes user provided form attributes
      def initialize( curation_concern, current_ability, attributes )
        @curation_concern = curation_concern
        @current_ability = current_ability
        @attributes = attributes
        @attributes = attributes.to_h.with_indifferent_access unless attributes.is_a? EnvironmentAttributes
      end

      ##
      # @!attribute [rw] attributes
      #   @return [Hash]
      # @!attribute [rw] curation_concern
      #   @return [Object]
      # @!attribute [rw] current_ability
      #   @return [Hyrax::Ability]
      attr_accessor :curation_concern, :current_ability, :attributes

      # @return [User] the user from the current_ability
      def user
        current_ability.current_user
      end

    end

  end

end
