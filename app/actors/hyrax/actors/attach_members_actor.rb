# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/actors/hyrax/actors/attach_members_actor.rb" )

module Hyrax
  module Actors

    # monkey patch AttachMembersActor
    class AttachMembersActor < Hyrax::Actors::AbstractActor
      # #add is private and visible to alias_method
      # alias_method :monkey_add, :add

      private

        def add( env, id )
          return if id.blank?
          member = ActiveFedora::Base.find( id )
          return unless env.current_ability.can?( :edit, member )
          env.curation_concern.ordered_members << member
          current_user = env['warden'].user
          return unless curation_concern.respond_to? :provenance_child_add
          curation_concern.provenance_child_add( current_user: current_user,
                                                 child_id: id,
                                                 event_note: "AttachMembersActor" )
        end

        # Remove the object from the members set and the ordered members list
        def remove( curation_concern, id )
          return if id.blank?
          member = ActiveFedora::Base.find(id)
          curation_concern.ordered_members.delete(member)
          curation_concern.members.delete(member)
          return unless curation_concern.respond_to? :provenance_child_remove
          curation_concern.provenance_child_remove( current_user: current_user,
                                                    child_id: id,
                                                    event_note: "AttachMembersActor" )
        end

    end

  end
end

# see: https://blog.daveallie.com/clean-monkey-patching/
# module AttachMembersActorMonkeyExtension
#
#   def self.prepended( base )
#     base.singleton_class.prepend( MonkeyClassMethods )
#   end
#
#   module MonkeyClassMethods
#
#     def try_convert(obj_or_json_string)
#       super || JSON.parse(obj_or_json_string) rescue nil
#     end
#
#   end
#
#   def to_pretty_json
#     JSON.pretty_generate(self)
#   end
#
# end
#
# AttachMembersActor.prepend( AttachMembersActorMonkeyExtension )
