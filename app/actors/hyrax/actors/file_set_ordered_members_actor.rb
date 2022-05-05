# frozen_string_literal: true

module Hyrax
  module Actors
    class FileSetOrderedMembersActor < FileSetActor
      # monkey

      mattr_accessor :file_set_ordered_ordered_members_actor_debug_verbose, default: false
      #               default: Rails.configuration.file_set_actor_debug_verbose

      # Adds representative and thumbnail to work; sets file_set visibility
      # @param [ActiveFedora::Base] work the parent work
      # @param [Hash] file_set_params
      def attach_to_work(work, file_set_params = {})
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "work.id=#{work.id}",
                                               "file_set_params=#{file_set_params}",
                                               "" ] if file_set_ordered_ordered_members_actor_debug_verbose
        file_set.visibility = work.visibility unless assign_visibility?(file_set_params)
        work.representative = file_set if work.representative_id.blank?
        work.thumbnail = file_set if work.thumbnail_id.blank?
      end
    end
  end
end
