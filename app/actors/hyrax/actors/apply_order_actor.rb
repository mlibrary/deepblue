module Hyrax
  module Actors
    class ApplyOrderActor < AbstractActor

      APPLY_ORDER_ACTOR_VERBOSE = false

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        ::Deepblue::LoggingHelper.bold_debug "ApplyOrderActor.update: next_actor = #{next_actor.class.name}" if APPLY_ORDER_ACTOR_VERBOSE
        ordered_member_ids = env.attributes.delete(:ordered_member_ids)
        sync_members(env, ordered_member_ids) &&
          apply_order(env.curation_concern, ordered_member_ids) &&
          next_actor.update(env)
      end

      private

        def can_edit_both_works?(env, work)
          rv = env.current_ability.can?(:edit, work) && env.current_ability.can?(:edit, env.curation_concern)
          # ::Deepblue::LoggingHelper.bold_debug "ApplyOrderActor.update: can_edit_both_works? = #{rv}" if APPLY_ORDER_ACTOR_VERBOSE
          rv
        end

        def sync_members(env, ordered_member_ids)
          ::Deepblue::LoggingHelper.bold_debug "ApplyOrderActor.sync_members ordered_member_ids = #{ordered_member_ids}" if APPLY_ORDER_ACTOR_VERBOSE
          return true if ordered_member_ids.nil?
          cleanup_ids_to_remove_from_curation_concern(env.curation_concern, ordered_member_ids)
          add_new_work_ids_not_already_in_curation_concern(env, ordered_member_ids)
          env.curation_concern.errors[:ordered_member_ids].empty?
        end

        # @todo Why is this not doing work.save?
        # @see Hyrax::Actors::AddToWorkActor for duplication
        def cleanup_ids_to_remove_from_curation_concern(curation_concern, ordered_member_ids)
          ::Deepblue::LoggingHelper.bold_debug "ApplyOrderActor.cleanup_ids_to_remove_from_curation_concern ordered_member_ids = #{ordered_member_ids}" if APPLY_ORDER_ACTOR_VERBOSE
          (curation_concern.ordered_member_ids - ordered_member_ids).each do |old_id|
            work = ::PersistHelper.find(old_id)
            curation_concern.ordered_members.delete(work)
            curation_concern.members.delete(work)
          end
        end

        def add_new_work_ids_not_already_in_curation_concern(env, ordered_member_ids)
          ::Deepblue::LoggingHelper.bold_debug "ApplyOrderActor.add_new_work_ids_not_already_in_curation_concern ordered_member_ids = #{ordered_member_ids}" if APPLY_ORDER_ACTOR_VERBOSE
          (ordered_member_ids - env.curation_concern.ordered_member_ids).each do |work_id|
            work = ::PersistHelper.find(work_id)
            if can_edit_both_works?(env, work)
              env.curation_concern.ordered_members << work
              env.curation_concern.save!
            else
              env.curation_concern.errors[:ordered_member_ids] << "Works can only be related to each other if user has ability to edit both."
            end
          end
        end

        def apply_order(curation_concern, new_order)
          ::Deepblue::LoggingHelper.bold_debug "ApplyOrderActor.apply_order new_order = #{new_order}" if APPLY_ORDER_ACTOR_VERBOSE
          return true unless new_order
          curation_concern.ordered_member_proxies.each_with_index do |proxy, index|
            unless new_order[index]
              proxy.prev.next = curation_concern.ordered_member_proxies.last.next
              break
            end
            proxy.proxy_for = ::PersistHelper.id_to_uri(new_order[index])
            proxy.target = nil
          end
          curation_concern.list_source.order_will_change!
          true
        end
    end
  end
end
