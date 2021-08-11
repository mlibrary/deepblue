module Hyrax
  module Actors
    # Responsible for generating the workflow for the given curation_concern.
    # Done through direct collaboration with the configured Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    #
    # @see Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    # @see Hyrax::Workflow::WorkflowFactory for default workflow factory
    class InitializeWorkflowActor < AbstractActor
      class_attribute :workflow_factory
      self.workflow_factory = ::Hyrax::Workflow::WorkflowFactory

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
          next_actor.create(env) && create_workflow(env)
      end

      def update(env)
        # A work that was a draft is now being published ( the admin set is no longer the Draft Admin Set ), 
        # so you need to put it in the mediated workflow.
        if ( env.curation_concern.to_sipity_entity&.workflow_state_name.eql?("draft")  && env.curation_concern.admin_set_id != ::Deepblue::DraftAdminSetService.draft_admin_set_id )
          work_id = env.curation_concern.id

          #Get the entity
          entity = env.curation_concern.to_sipity_entity
          wf = env.curation_concern.active_workflow 

          # initiate the workflow state
          action_name = "pending_review"

          action = Sipity::WorkflowAction.find_or_create_by!( workflow: wf, name: action_name )
          wf_state = Sipity::WorkflowState.find_or_create_by!( workflow: wf, name: action_name )

          entity.update!( workflow: wf, workflow_state_id: action.id, workflow_state: wf_state )

          next_actor.create(env)
        else
          super
        end
      end


      private

        # @return [TrueClass]
        def create_workflow(env)
          workflow_factory.create(env.curation_concern, env.attributes, env.user)
        end
    end
  end
end