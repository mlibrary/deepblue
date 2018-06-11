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
          member = ActiveFedora::Base.find( id )
          return unless env.current_ability.can?( :edit, member )
          env.curation_concern.ordered_members << member
          current_user = env['warden'].user
          curation_concern.provenance_add( current_user: current_user, child_id: id ) if curation_concern.respond_to? :provenance_add
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
