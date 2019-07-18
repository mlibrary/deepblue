module Hyrax
  # Injects a search builder filter to hide documents marked as suppressed
  module FilterSuppressed
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:only_active_works]
    end

    def only_active_works(solr_parameters)
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "solr_parameters=#{solr_parameters}",
      #                                        "" ]
#byebug
      if ( current_ability.admin? || depositor? )
        solr_parameters[:fq] ||= [] 
      else
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << '-suppressed_bsi:true'
      end
    end


    private

      def current_work
        ::SolrDocument.find(blacklight_params[:id])
      end

      def user_has_active_workflow_role?
        Hyrax::Workflow::PermissionQuery.scope_permitted_workflow_actions_available_for_current_state(user: current_ability.current_user, entity: current_work).any?
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
