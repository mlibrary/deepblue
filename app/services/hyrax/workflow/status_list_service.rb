# frozen_string_literal: true
module Hyrax
  module Workflow
    # Finds a list of works that we can perform a workflow action on
    class StatusListService

      mattr_accessor :status_list_service_debug_verbose, default: false

      # @param context [#current_user, #logger]
      # @param filter_condition [String] a solr filter
      def initialize(context, filter_condition)
        @context = context
        @filter_condition = filter_condition
      end

      attr_reader :context

      # TODO: We will want to paginate this
      # @return [Array<StatusRow>] a list of results that the given user can take action on.
      def each
        return enum_for(:each) unless block_given?
        solr_documents.each do |doc|
          yield doc
        end
      end

      # TODO: Make this private for version 1.0
      def user
        context.current_user
      end

      private

      delegate :logger, to: :context

      # @return [Hash<String,SolrDocument>] a hash of id to solr document
      def solr_documents
        search_solr.map { |result| ::SolrDocument.new(result) }
      end

      def search_solr
        actionable_roles = roles_for_user
        logger.debug("Actionable roles for #{user.user_key} are #{actionable_roles}")
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "user.user_key=#{user.user_key}",
                                               "actionable_roles=#{actionable_roles}",
                                               "" ] if status_list_service_debug_verbose
        return [] if actionable_roles.empty?
        q = query(actionable_roles)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "q=#{q}",
                                               "" ] if status_list_service_debug_verbose
        WorkRelation.new.search_with_conditions(q, rows: 1000, method: :post)
      end

      def query(actionable_roles)
        ["{!terms f=actionable_workflow_roles_ssim}#{actionable_roles.join(',')}",
         @filter_condition]
      end

      # @return [Array<String>] the list of workflow-role combinations this user has
      def roles_for_user
        Sipity::Workflow.all.flat_map do |wf|
          workflow_roles_for_user_and_workflow(wf).map do |wf_role|
            "#{wf.permission_template.source_id}-#{wf.name}-#{wf_role.role.name}"
          end
        end
      end

      # @param workflow [Sipity::Workflow]
      # @return [ActiveRecord::Relation<Sipity::WorkflowRole>]
      def workflow_roles_for_user_and_workflow(workflow)
        Hyrax::Workflow::PermissionQuery.scope_processing_workflow_roles_for_user_and_workflow(user: user, workflow: workflow)
      end
    end
  end
end
