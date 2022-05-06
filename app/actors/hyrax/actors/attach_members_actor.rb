# frozen_string_literal: true

# monkey

module Hyrax

  module Actors
    ##
    # Attach or remove child works to/from this work. This decodes parameters
    # that follow the rails nested parameters conventions:
    # e.g.
    #   'work_members_attributes' => {
    #     '0' => { 'id' => '12312412'},
    #     '1' => { 'id' => '99981228', '_destroy' => 'true' }
    #   }
    #
    # The goal of this actor is to mutate the +#ordered_members+ with as few writes
    # as possible, because changing +#ordered_members+ is slow. This class only
    # writes changes, not the full ordered list.
    #
    # The +env+ for this actor may contain a +Valkyrie::Resource+ or an
    # +ActiveFedora::Base+ model, as required by the caller.
    class AttachMembersActor < Hyrax::Actors::AbstractActor

      mattr_accessor :attach_members_actor_debug_verbose,
                     default: Rails.configuration.attach_members_actor_debug_verbose

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        # log_event( env: env )
        attributes_collection = env.attributes.delete(:work_members_attributes)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "AttachMembersActor.update: next_actor = #{next_actor.class.name}",
                                               "" ] if attach_members_actor_debug_verbose
        assign_nested_attributes_for_collection(env, attributes_collection) &&
          next_actor.update(env)
      end

      private

        # Attaches any unattached members.  Deletes those that are marked _delete
      # @param [Hyrax::Actors::Environment] env
      # @param [Hash<Hash>] attributes_collection a collection of members
      #
      # rubocop:disable Metrics/CyclomaticComplexity
      # Complexity in this method is incleased by dual AF/Valkyrie support
      # when removing AF, we should be able to reduce it substantially.
        def assign_nested_attributes_for_collection(env, attributes_collection)
          return true unless attributes_collection

          attributes         = extract_attributes(attributes_collection)
          cast_concern       = !env.curation_concern.is_a?(Valkyrie::Resource)
          resource           = cast_concern ? env.curation_concern.valkyrie_resource : env.curation_concern
          inserts, destroys  = split_inserts_and_destroys(attributes, resource)

          # short circuit to avoid casting unnecessarily
          return true if destroys.empty? && inserts.empty?
          # we fail silently if we can't insert the object; this is for legacy
          # compatibility
          return true unless check_permissions(ability: env.current_ability,
                                               inserts: inserts,
                                               destroys: destroys)
          update_members(resource: resource, inserts: inserts, destroys: destroys)

          return true unless cast_concern
          env.curation_concern = Hyrax.metadata_adapter
                                      .resource_factory
                                      .from_resource(resource: resource)

          # # checking for existing works to avoid rewriting/loading works that are
          # # already attached
          # existing_works = env.curation_concern.member_ids
          # attributes_collection.each do |attributes|
          #   next if attributes['id'].blank?
          #   if existing_works.include?(attributes['id'])
          #     remove( env, env.curation_concern, attributes['id']) if has_destroy_flag?(attributes)
          #   else
          #     add(env, attributes['id'])
          #   end
          # end
        end

        # # Adds the item to the ordered members so that it displays in the items
        # # along side the FileSets on the show page
        # def add_old(env, id)
        #   member = ::PersistHelper.find( id )
        #   return unless env.current_ability.can?(:edit, member)
        #   env.curation_concern.ordered_members << member
        # end
        #
        # # Remove the object from the members set and the ordered members list
        # def remove_old(curation_concern, id)
        #   member = ::PersistHelper.find( id )
        #   curation_concern.ordered_members.delete(member)
        #   curation_concern.members.delete(member)
        # end
        #
        # def add( env, id )
        #   # ::Deepblue::LoggingHelper.bold_debug "AttachMembersActor.add: id = #{id}"
        #   return if id.blank?
        #   member = ::PersistHelper.find( id )
        #   child_title = member.title
        #   # is this check necessary?
        #   can_do_it = env.current_ability.can?( :edit, member )
        #   # ::Deepblue::LoggingHelper.bold_debug "AttachMembersActor.add: id = #{id} can_do_it = #{can_do_it}"
        #   return unless can_do_it
        #   # ::Deepblue::LoggingHelper.bold_debug "AttachMembersActor.add: adding ordered member id = #{id}"
        #   env.curation_concern.ordered_members << member
        #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                          ::Deepblue::LoggingHelper.called_from,
        #                                          "provenance_child_add",
        #                                          "parent.id=#{env.curation_concern.id}",
        #                                          "child_id=#{id}",
        #                                          "child_title=#{child_title}",
        #                                          "event_note=AttachMembersActor",
        #                                          "" ] if attach_members_actor_debug_verbose
        #   return unless env.curation_concern.respond_to? :provenance_child_add
        #   current_user = env.user
        #   env.curation_concern.provenance_child_add( current_user: current_user,
        #                                              child_id: id,
        #                                              child_title: child_title,
        #                                              event_note: "AttachMembersActor" )
        # end
        #
        # # Remove the object from the members set and the ordered members list
        # def remove( env, curation_concern, id )
        #   # ::Deepblue::LoggingHelper.bold_debug "AttachMembersActor.remove: id = #{id}"
        #   return if id.blank?
        #   member = ::PersistHelper.find( id )
        #   child_title = member.title
        #   curation_concern.ordered_members.delete(member)
        #   curation_concern.members.delete(member)
        #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                          ::Deepblue::LoggingHelper.called_from,
        #                                          "provenance_child_remove",
        #                                          "parent.id=#{curation_concern.id}",
        #                                          "child_id=#{id}",
        #                                          "child_title=#{child_title}",
        #                                          "event_note=AttachMembersActor",
        #                                          "" ] if attach_members_actor_debug_verbose
        #   return unless curation_concern.respond_to? :provenance_child_remove
        #   current_user = env.user
        #   curation_concern.provenance_child_remove( current_user: current_user,
        #                                             child_id: id,
        #                                             child_title: child_title,
        #                                             event_note: "AttachMembersActor" )
        # end

      def check_permissions(ability:, inserts: [], **_opts)
        inserts.all? { |id| ability.can?(:edit, id) }
      end

      def extract_attributes(collection)
        collection
          .sort_by { |i, _| i.to_i }
          .map { |_, attributes| attributes }
      end

      # Determines if a hash contains a truthy _destroy key.
      # rubocop:disable Naming/PredicateName
      def has_destroy_flag?(hash)
        ActiveFedora::Type::Boolean.new.cast(hash['_destroy'])
      end

      def provenance_log_add( parent:, id: )
        return if parent.blank?
        return if id.blank?
        member = ::PersistHelper.find( id )
        child_title = member.title
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "parent.id=#{parent.id}",
                                               "child_id=#{id}",
                                               "child_title=#{child_title}",
                                               "event_note=AttachMembersActor",
                                               "" ] if attach_members_actor_debug_verbose
        return unless parent.respond_to? :provenance_child_add
        current_user = env.user
        parent.provenance_child_add( current_user: current_user,
                                                   child_id: id,
                                                   child_title: child_title,
                                                   event_note: "AttachMembersActor" )
      end

      def provenance_log_remove( parent:, id: )
        return if parent.blank?
        return if id.blank?
        member = ::PersistHelper.find( id )
        child_title = member.title
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "parent.id=#{parent.id}",
                                               "child_id=#{id}",
                                               "child_title=#{child_title}",
                                               "event_note=AttachMembersActor",
                                               "" ] if attach_members_actor_debug_verbose
        return unless parent.respond_to? :provenance_child_remove
        current_user = env.user
        parent.provenance_child_remove( current_user: current_user,
                                                  child_id: id,
                                                  child_title: child_title,
                                                  event_note: "AttachMembersActor" )
      end

      def split_inserts_and_destroys(attributes, resource)
        current_member_ids = resource.member_ids.map(&:id)

        destroys = attributes.select do |col_hash|
          ActiveModel::Type::Boolean.new.cast(col_hash['_destroy'])
        end

        inserts  = (attributes - destroys).map { |h| h['id'] }.compact - current_member_ids
        destroys = destroys.map { |h| h['id'] }.compact & current_member_ids

        [inserts, destroys]
      end

      def update_members(resource:, inserts: [], destroys: [])
        inserts.each { |id| provenance_log_add( parent: resource, id: id ) }
        destroys.each { |id| provenance_log_remove( parent: resource, id: id ) }
        resource.member_ids += inserts.map  { |id| Valkyrie::ID.new(id) }
        resource.member_ids -= destroys.map { |id| Valkyrie::ID.new(id) }
      end

      # rubocop:enable Naming/PredicateName
    end

  end

end
