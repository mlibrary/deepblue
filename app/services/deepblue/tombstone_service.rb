# frozen_string_literal: true

module Deepblue

  class TombstoneService

    mattr_accessor :tombstone_service_debug_verbose, default: false

    def self.tombstone_work( work:, epitaph:, current_user:, msg_handler: nil )
      msg_handler ||= ::Deepblue::MessageHandlerDebugOnly.new()
      debug_verbose = msg_handler.debug_verbose
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "work=#{work.id}",
                               "work.tombstone=#{work.tombstone}",
                               "epitaph=#{epitaph}",
                               "current_user=#{current_user}",
                               "" ] if debug_verbose
      return if work.tombstone.present?

      depositor_at_tombstone = work.depositor
      visibility_at_tombstone = work.visibility
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

      # # The state indicates if an object is Published or not.
      # # Tombstone objects are Published first and then Tombstoned.
      # # If you set the state to inactive, you will not be able to Filter for Restricted, Published works,
      # # in the works dashboard and find the Tombstoned works.
      # # To find them, you would have to search for Restricted, Under Review works, which
      # # does not reflect the works true status/state.
      # #self.state = Vocab::FedoraResourceStatus.inactive
      # self.depositor = depositor
      work.tombstone = [epitaph]

      work.file_sets.each do |file_set|
        # TODO: FileSet#entomb!
        file_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
      work.save
      work.provenance_tombstone( current_user: current_user,
                                 epitaph: epitaph,
                                 depositor_at_tombstone: depositor_at_tombstone,
                                 visibility_at_tombstone: visibility_at_tombstone )
      ::DataDenExportService.tombstone_work( cc: work )
    end

  end

end
