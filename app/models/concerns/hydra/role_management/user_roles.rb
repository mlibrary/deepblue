# frozen_string_literal: true

module Hydra
  module RoleManagement
    # Module offering methods for user behavior managing roles and groups
    module UserRoles
      extend ActiveSupport::Concern

      mattr_accessor :hydra_role_management_user_roles_debug_verbose,
                     default: Rails.configuration.hydra_role_management_user_roles_debug_verbose

      included do
        has_and_belongs_to_many :roles
      end

      def groups
        ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "", bold_puts: false] if hydra_role_management_user_roles_debug_verbose
        g = roles.map(&:name)
        g += ['registered'] unless new_record? || guest?
        ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "g=#{g}",
                                              "", bold_puts: false] if hydra_role_management_user_roles_debug_verbose
        g
      end

      def guest?
        if defined?(DeviseGuests)
          self[:guest]
        else
          false
        end
      end

      def admin?
        roles.where(name: 'admin').exists?
      end
    end
  end
end
