# frozen_string_literal: true
module Hyrax
  module Actors
    ##
    # An actor that registers a DOI using the configured registar
    # This actor should come after the model actor which saves the work
    #
    # @example use in middleware
    #   stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
    #     # middleware.use OtherMiddleware
    #     middleware.use Hyrax::Actors::DoiActor
    #     # middleware.use MoreMiddleware
    #   end
    #
    #   env = Hyrax::Actors::Environment.new(object, ability, attributes)
    #   last_actor = Hyrax::Actors::Terminator.new
    #   stack.build(last_actor).create(env)
    class DoiActor < BaseActor
      delegate :destroy, to: :next_actor

      ##
      # @return [Boolean]
      #
      # @see Hyrax::Actors::AbstractActor
      def create(env)
        # Assume the model actor has already run and saved the work
        create_or_update_doi(env.curation_concern) && next_actor.create(env)
      end

      ##
      # @return [Boolean]
      #
      # @see Hyrax::Actors::AbstractActor
      def update(env)
        # Ensure that the work has any changed attributes persisted before we create the job
        apply_save_data_to_curation_concern(env)
        save(env)

        create_or_update_doi(env.curation_concern) && next_actor.update(env)
      end

      private

      def create_or_update_doi(work)
        return true # disable for now
        return true unless doi_enabled_work_type?(work) && Flipflop.enabled?(:doi_minting)

        RegisterDoiJob.perform_later( id: work.id,
                                      registrar: work.doi_registrar.presence,
                                      registrar_opts: work.doi_registrar_opts )
      end

      # Check if work is DOI enabled
      def doi_enabled_work_type?(work)
        work.class.ancestors.include? ::Deepblue::DoiBehavior
      end
    end
  end
end
