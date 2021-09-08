# frozen_string_literal: true

module Hyrax

  # Overrides FilterSuppressed filter to hide documents marked as
  # suppressed when the current user is permitted to take no workflow
  # actions for the work's current state
  #
  # Assumes presence of `blacklight_params[:id]` and a SolrDocument
  # corresponding to that `:id` value
  module FilterSuppressedWithRoles
    extend ActiveSupport::Concern

    mattr_accessor :hyrax_filter_suppressed_with_roles_debug_verbose, default: false

    include FilterSuppressed

    # Skip the filter if the current user is permitted to take
    # workflow actions on the work corresponding to the SolrDocument
    # with id = `blacklight_params[:id]`
    def only_active_works(solr_parameters)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "solr_parameters=#{solr_parameters}",
                                             "" ] if hyrax_filter_suppressed_with_roles_debug_verbose
      return if current_ability.current_user.guest? || current_ability.current_user.new_record?
      return if user_has_active_workflow_role? || depositor?
      super
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_parameters=#{solr_parameters}",
                                             "" ] if hyrax_filter_suppressed_with_roles_debug_verbose
    end

    private

      def current_work
        ::SolrDocument.find(blacklight_params[:id])
      end

      def user_has_active_workflow_role?
        Hyrax::Workflow::PermissionQuery.scope_permitted_workflow_actions_available_for_current_state(user: current_ability.current_user,
                                                                                                      entity: current_work).any?
      rescue PowerConverter::ConversionError
        # The current_work doesn't have a sipity workflow entity
        false
      end

      def depositor?
        depositors = current_work[DepositSearchBuilder.depositor_field]

        return false if depositors.nil?

        depositors.first == current_ability.current_user.user_key
      end
  end

end
