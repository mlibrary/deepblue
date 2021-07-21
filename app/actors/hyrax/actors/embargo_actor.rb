# frozen_string_literal: true

module Hyrax

  module Actors

    class EmbargoActor

      mattr_accessor :embargo_actor_debug_verbose, default: false

      include ::Hyrax::EmbargoHelper
      attr_reader :work

      # @param [Hydra::Works::Work] work
      def initialize(env, work)
        @env = env
        @work = work
      end

      def destroy
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if embargo_actor_debug_verbose
        deactivate_embargo( curation_concern: work, current_user: @env.user, copy_visibility_to_files: false )
      end

    end

  end

end
