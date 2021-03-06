# frozen_string_literal: true

module Hyrax

  module Actors

    class EmbargoActor

      EMBARGO_ACTOR_DEBUG_VERBOSE = false

      include ::Hyrax::EmbargoHelper
      attr_reader :work

      # @param [Hydra::Works::Work] work
      def initialize(work)
        @work = work
      end

      def destroy
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               ::Deepblue::LoggingHelper.obj_class( "work", work ),
                                               "" ] if EMBARGO_ACTOR_DEBUG_VERBOSE
        deactivate_embargo( curation_concern: work, current_user: env.user, copy_visibility_to_files: false )
      end

    end

  end

end
