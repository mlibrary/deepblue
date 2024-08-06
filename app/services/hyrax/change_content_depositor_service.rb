# frozen_string_literal: true
# Reviewed: hyrax4

# monkey override

module Hyrax

  class ChangeContentDepositorService

    mattr_accessor :change_content_depositor_service_debug_verbose, default: false

    # Set the given `user` as the depositor of the given `work`; If
    # `reset` is true, first remove all previous permissions.
    #
    # @param work [ActiveFedora::Base, Valkyrie::Resource] the work
    #             that is receiving a change of depositor
    # @param user [User] the user that will "become" the depositor of
    #             the given work
    # @param reset [TrueClass, FalseClass] when true, first clear
    #              permissions for the given work and contained file
    #              sets; regardless of true/false make the given user
    #              the depositor of the given work
    def self.call( work, user, reset )
      case work
      when ActiveFedora::Base
        call_af(work, user, reset)
      when Valkyrie::Resource
        call_valkyrie(work, user, reset)
      end
    end

    def self.call_af(work, user, reset)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work=#{work}",
                                             "user=#{user}",
                                             "reset=#{reset}",
                                             "" ] if change_content_depositor_service_debug_verbose
      previous_user = ::User.find_by_user_key(work.depositor)
      work.proxy_depositor = work.depositor
      work.permissions = [] if reset
      work.apply_depositor_metadata(user)
      work.file_sets.each do |f|
        f.permissions = [] if reset
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
                                             "" ] if change_content_depositor_service_debug_verbose
      work.provenance_transfer( current_user: user,
                                previous_user: previous_user,
                                event_note: event_note ) if work.respond_to? :provenance_transfer
      work
    end
    private_class_method :call_af

    # @todo Should this include some dependency injection regarding
    # the Hyrax.persister and Hyrax.custom_queries?
    def self.call_valkyrie(work, user, reset)
      if reset
        work.permission_manager.acl.permissions = []
        work.permission_manager.acl.save
      end

      work.proxy_depositor = work.depositor
      apply_depositor_metadata(work, user)

      apply_valkyrie_changes_to_file_sets(work: work, user: user, reset: reset)

      Hyrax.persister.save(resource: work)
      work
    end
    private_class_method :call_valkyrie

    def self.apply_depositor_metadata(resource, depositor)
      depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor
      resource.depositor = depositor_id if resource.respond_to? :depositor=
      Hyrax::AccessControlList.new(resource: resource).grant(:edit).to(::User.find_by_user_key(depositor_id)).save
    end
    private_class_method :apply_depositor_metadata

    def self.apply_valkyrie_changes_to_file_sets(work:, user:, reset:)
      Hyrax.custom_queries.find_child_file_sets(resource: work).each do |f|
        if reset
          f.permission_manager.acl.permissions = []
          f.permission_manager.acl.save
        end
        apply_depositor_metadata(f, user)
        Hyrax.persister.save(resource: f)
      end
    end
    private_class_method :apply_valkyrie_changes_to_file_sets

  end

end
