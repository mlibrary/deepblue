# frozen_string_literal: true

module Hyrax
  module Actors

    # see AttachMembersActor for original code
    # Provenance logging for:
    #
    # Attach or remove child works to/from this work. This decodes parameters
    # that follow the rails nested parameters conventions:
    # e.g.
    #   'work_members_attributes' => {
    #     '0' => { 'id' = '12312412'},
    #     '1' => { 'id' = '99981228', '_destroy' => 'true' }
    #   }

    class BeforeAttachMembersActor < AbstractEventActor

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update( env )
        env.log_event( next_actor: next_actor )
        attributes_collection = env.attributes.values_at( :work_members_attributes )
        Deepblue::LoggingHelper.bold_debug "BeforeAttachMembersActor.update: next_actor = #{next_actor.class.name}"
        assign_nested_attributes_for_collection( env, attributes_collection ) && next_actor.update( env )
      end

      protected

        # Provenance log for attaching and unattaching members.
        # @param [Hash<Hash>] a collection of members
        def assign_nested_attributes_for_collection( env, attributes_collection )
          return true if attributes_blank? attributes_collection
          return true unless env.curation_concern.respond_to? :provenance_child_add
          attributes_collection = attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
          # checking for existing works to avoid rewriting/loading works that are already attached
          existing_works = env.curation_concern.member_ids
          current_user = env.user
          attributes_collection.each do |attributes|
            next if attributes['id'].blank?
            if existing_works.include?( attributes['id'] )
              remove( env, attributes['id'], current_user ) if has_destroy_flag?( attributes )
            else
              add( env, attributes['id'], current_user )
            end
          end
        end

        # provenance log: Adds the item to the ordered members so that it displays in the items
        # along side the FileSets on the show page
        def add( env, id, current_user )
          member = ActiveFedora::Base.find( id )
          return unless env.current_ability.can?( :edit, member )
          env.curation_concern.provenance_child_add( current_user: current_user, child_id: id, event_note: 'BeforeAttachMembersActor' )
        end

        # Determines if a hash contains a truthy _destroy key.
        # rubocop:disable Style/PredicateName
        def has_destroy_flag?( hash )
          ActiveFedora::Type::Boolean.new.cast( hash['_destroy'] )
        end
        # rubocop:enable Style/PredicateName

        # provenance log for: Remove the object from the members set and the ordered members list
        def remove( env, id, current_user )
          env.curation_concern.provenance_child_remove( current_user: current_user, child_id: id, event_note: 'BeforeAttachMembersActor' )
        end

    end

  end
end
