# frozen_string_literal: true

module Hyrax
  module Actors
    # Ensures that the default AdminSet id is set if this form doesn't have
    # an admin_set_id provided. This should come before the
    # Hyrax::Actors::InitializeWorkflowActor, so that the correct
    # workflow can be kicked off.
    #
    # @see Hyrax::EnsureWellFormedAdminSetService
    #
    # @note Creates AdminSet, Hyrax::PermissionTemplate, Sipity::Workflow (with activation)
    class DefaultAdminSetActor < Hyrax::Actors::AbstractActor

      mattr_accessor :default_admin_set_actor_debug_verbose,
                     default: Rails.configuration.default_admin_set_actor_debug_verbose

      # Hyrax provides a service that ensures well formed admin sets.
      # It is possible that downstream implementers might seek to
      # override this behavior.  The class attribute provicdes a means
      # to override that behavior.
      class_attribute :ensure_well_formed_admin_set_service
      self.ensure_well_formed_admin_set_service = Hyrax::EnsureWellFormedAdminSetService

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        ensure_admin_set_attribute!(env)
        next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        ensure_admin_set_attribute!(env)
        next_actor.update(env)
      end

      private

      # This method:
      #
      # - ensures that the env.attributes[:admin_set_id] is set
      # - ensures that the permission template for the admin set is correct
      def ensure_admin_set_attribute!(env)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env.attributes[:admin_set_id]=#{env.attributes[:admin_set_id]}",
                                               "" ] if default_admin_set_actor_debug_verbose
        # begin new hyrax v3 code
        # # These logical hoops copy the prior behavior of the code;
        # # With a small logical caveat.  If the given curation_concern
        # # has an admin_set_id, we now verify that that admin set is
        # # well formed.
        # given_admin_set_id = env.attributes[:admin_set_id].presence || env.curation_concern.admin_set_id.presence
        # admin_set_id = ensure_well_formed_admin_set_service.call(admin_set_id: given_admin_set_id)
        # env.attributes[:admin_set_id] = given_admin_set_id || admin_set_id
        # end new hyrax v3 code

        if env.attributes[:admin_set_id].present?
          ensure_permission_template!(admin_set_id: env.attributes[:admin_set_id])
        elsif env.curation_concern.admin_set_id.present?
          env.attributes[:admin_set_id] = env.curation_concern.admin_set_id
          ensure_permission_template!(admin_set_id: env.attributes[:admin_set_id])
        else
          AdminSet.find_each do |admin_set|
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "admin_set=#{admin_set}",
                                                   "admin_set.title=#{admin_set&.title}",
                                                   "" ] if default_admin_set_actor_debug_verbose
                                                   byebug
            unless ( (admin_set.id.eql? Rails.configuration.default_admin_set_id) &&
                                       (admin_set&.title&.first != Rails.configuration.data_set_admin_set_title) )
              ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                     ::Deepblue::LoggingHelper.called_from,
                                                     "assigning admin set id=#{admin_set.id}",
                                                     "" ] if default_admin_set_actor_debug_verbose
              env.attributes[:admin_set_id] = admin_set.id
              break
            end
          end
        end
      end

      def ensure_permission_template!(admin_set_id:)
        Hyrax::PermissionTemplate.find_by(source_id: admin_set_id) || create_permission_template!(source_id: admin_set_id)
      end

      def default_admin_set_id
        AdminSet.find_or_create_default_admin_set_id
      end

      # Creates a Hyrax::PermissionTemplate for the given AdminSet
      def create_permission_template!(source_id:)
        Hyrax::PermissionTemplate.create!(source_id: source_id)
      end
    end
  end
end
