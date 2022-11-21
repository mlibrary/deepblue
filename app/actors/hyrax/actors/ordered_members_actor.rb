# frozen_string_literal: true

module Hyrax
  module Actors
    class OrderedMembersActor < FileSetActor
      # monkey

      mattr_accessor :ordered_members_actor_debug_verbose, default: false
      #               default: Rails.configuration.ordered_members_actor_debug_verbose

      include Lockable
      attr_reader :ordered_members, :user

      def initialize(ordered_members, user)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "ordered_members&.size=#{ordered_members&.size}",
                                               "user=#{user}",
                                               "" ], bold_puts: true if ordered_members_actor_debug_verbose
        @ordered_members = ordered_members
        @user = user
      end

      # Adds FileSets to the work using ore:Aggregations.
      # Locks to ensure that only one process is operating on the list at a time.
      # @param [ActiveFedora::Base] work the parent work
      def attach_ordered_members_to_work(work)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "work.id=#{work.id}",
                                               "" ], bold_puts: true if ordered_members_actor_debug_verbose
        acquire_lock_for(work.id) do
          work.ordered_members = ordered_members
          work.save
          ordered_members.each do |file_set|
            Hyrax.config.callback.run(:after_create_fileset, file_set, user, warn: false)
          end
        end
      end
    end
  end
end
