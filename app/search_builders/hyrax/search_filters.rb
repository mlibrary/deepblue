# frozen_string_literal: true
# Reviewed: hyrax4

# monkey override

module Hyrax
  module SearchFilters
    extend ActiveSupport::Concern
    include Hyrax::FilterByType
    include FilterSuppressed

    # TODO: move this to Hydra::AccessControlsEnforcement
    # @param access [String] what access level to set. Either 'read' or 'edit'
    # @return [SearchBuilder]
    def with_access(access)
      @discovery_permissions = Array.wrap(access)
      self
    end

    # Override Hydra::AccessControlsEnforcement (or Hydra::PolicyAwareAccessControlsEnforcement)
    # Allows admin users to see everything (don't apply any gated_discovery_filters for those users)
    def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
      return [] if ability&.admin? # Update: hyrax4
      super
    end

    private

      def current_user_key
        current_user.user_key
      end

      def current_user
        scope.current_user
      end
  end
end
