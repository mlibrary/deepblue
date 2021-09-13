module Hyrax
  module Actors
    # Responsible for generating the workflow for the given curation_concern.
    # Done through direct collaboration with the configured Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    #
    # @see Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    # @see Hyrax::Workflow::WorkflowFactory for default workflow factory
    class InitializeWorkflowActor < AbstractActor

      mattr_accessor :initialize_workflow_actor_debug_verbose,
                     default: Rails.configuration.initialize_workflow_actor_debug_verbose

      class_attribute :workflow_factory
      self.workflow_factory = ::Hyrax::Workflow::WorkflowFactory

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
          next_actor.create(env) && create_workflow(env)
      end

      def update(env)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env=#{env}",
                                               "env.curation_concern.id=#{env.curation_concern.id}",
                                               "env.attributes=#{env.attributes}",
                                               "env.attributes[:admin_set_id]=#{env.attributes[:admin_set_id]}",
                                               "env.user=#{env.user}",
                                               "" ] if initialize_workflow_actor_debug_verbose
        # A work that was a draft is now being published ( the admin set is no longer the Draft Admin Set ),
        # so you need to put it in the mediated workflow.
        admin_set_id = env.attributes[:admin_set_id]
        if ::Deepblue::DraftAdminSetService.draft_admin_set_id != admin_set_id &&
             ::Deepblue::DraftAdminSetService.is_draft_curation_concern?( env.curation_concern )

          work_id = env.curation_concern.id
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "work_id=#{work_id}",
                                                 "" ] if initialize_workflow_actor_debug_verbose
          #Get the entity
          entity = env.curation_concern.to_sipity_entity
          entity.proxy_for.title = env.curation_concern.title
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "entity.class.name=#{entity.class.name}",
                                                 "entity=#{entity}",
                                                 "" ] if initialize_workflow_actor_debug_verbose
          wf = env.curation_concern.active_workflow


          # initiate the workflow state
          action_name = "pending_review"

          action = Sipity::WorkflowAction.find_or_create_by!( workflow: wf, name: action_name )
          wf_state = Sipity::WorkflowState.find_or_create_by!( workflow: wf, name: action_name )

          entity.update!( workflow: wf, workflow_state_id: action.id, workflow_state: wf_state )

          next_actor.update(env) && send_notification(env, entity, action)# TODO: should this be next_actor.update(env) ??


        else
          super
        end
      end


      private

        # @return [TrueClass]
        def create_workflow(env)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "env=#{env}",
                                                 "env.curation_concern.id=#{env.curation_concern.id}",
                                                 "env.attributes=#{env.attributes}",
                                                 "env.user=#{env.user}",
                                                 "" ] if initialize_workflow_actor_debug_verbose
          workflow_factory.create(env.curation_concern, env.attributes, env.user)
        end

        def send_notification(env, entity, action)
          #Send a notification letting it known that the work has transition from draft to mediated workflow
          notifier = Hyrax::Workflow::NotificationService.new(entity: entity, action: action, comment: true, user: env.user)

          notification = Sipity::Notification.new
          notification.id = 1
          notification.name ="Hyrax::Workflow::PendingReviewNotification"
          notification.notification_type ="email"
          now = Time.now.strftime("%Y-%m-%d")
          notification.created_at = now
          notification.updated_at = now

          notifier.send_notification(notification)
        end

    end
  end
end
