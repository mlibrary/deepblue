# frozen_string_literal: true

module Hyrax

  class ChangeContentDepositorService

    CHANGE_CONTENT_DEPOSITOR_SERVICE_DEBUG_VERBOSE = true

    # @param [ActiveFedora::Base] work
    # @param [User] user
    # @param [TrueClass, FalseClass] reset
    def self.call( work, user, reset )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work=#{work}",
                                             "user=#{user}",
                                             "reset=#{reset}",
                                             "" ] if CHANGE_CONTENT_DEPOSITOR_SERVICE_DEBUG_VERBOSE
      previous_user = ::User.find_by_user_key(work.depositor)
      work.proxy_depositor = work.depositor
      work.permissions = [] if reset
      work.apply_depositor_metadata(user)
      work.file_sets.each do |f|
        f.apply_depositor_metadata(user)
        f.save!
        f.provenance_transfer( current_user: user,
                               previous_user: previous_user,
                               event_note: "reset=#{reset}" ) if f.respond_to? :provenance_transfer
      end
      work.save!
      event_note = ChangeContentDepositorService.name
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work=#{work}",
                                             "user=#{user}",
                                             "previous_user=#{previous_user}",
                                             "event_note=#{event_note}",
                                             "" ] if CHANGE_CONTENT_DEPOSITOR_SERVICE_DEBUG_VERBOSE
      work.provenance_transfer( current_user: user,
                                previous_user: previous_user,
                                event_note: event_note ) if work.respond_to? :provenance_transfer
      work
    end

  end

end
