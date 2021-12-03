# frozen_string_literal: true

module Hyrax
  module Actors

    # see AddToWorkActor
    # provenance logging
    class BeforeAddToWorkActor < AbstractEventActor

      mattr_accessor :before_add_to_work_actor_debug_verbose,
                     default: Rails.configuration.before_add_to_work_actor_debug_verbose

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create( env )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env=#{env}",
                                               "" ] if before_add_to_work_actor_debug_verbose
        env.log_event( next_actor: next_actor ) if env.respond_to? :log_event
        work_ids = env.attributes.values_at( :in_works_ids )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "BeforeAddToWorkActor.create: next_actor = #{next_actor.class.name}",
                                           "work_ids=#{work_ids}",
                                           "" ] if before_add_to_work_actor_debug_verbose
        actor = next_actor
        actor.create( env ) && add_to_works( env, work_ids )
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update( env )
        env.log_event( next_actor: next_actor ) if env.respond_to? :log_event
        work_ids = env.attributes.values_at( :in_works_ids )
        Deepblue::LoggingHelper.bold_debug [ "BeforeAddToWorkActor.update: next_actor = #{next_actor.class.name}",
                                             "work_ids=#{work_ids}" ] if before_add_to_work_actor_debug_verbose
        actor = next_actor
        add_to_works( env, work_ids ) && actor.update( env )
      end

      protected

        def add_new_work_ids_not_already_in_curation_concern( env, new_work_ids )
          # add to new so long as the depositor for the parent and child matches, otherwise igmore
          (new_work_ids - env.curation_concern.in_works_ids).each do |work_id|
            work = ::PersistHelper.find( work_id )
            Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 "provenance_child_add",
                                                 "parent.id=#{work_id}",
                                                 "child_id=#{env.curation_concern.id}",
                                                 "child_title=#{env.curation_concern.title}",
                                                 "event_note=BeforeAddToWorkActor",
                                                 "can_edit_both_works?=#{can_edit_both_works?( env, work )}",
                                                  "" ] if before_add_to_work_actor_debug_verbose
            next unless work.respond_to? :provenance_child_add
            if can_edit_both_works?( env, work )
              work.provenance_child_add( current_user: env.user,
                                         child_id: env.curation_concern.id,
                                         child_title: env.curation_concern.title,
                                         event_note: 'BeforeAddToWorkActor' )
            end
          end
        end

        def add_to_works( env, new_work_ids )
          return true if attributes_blank? new_work_ids
          cleanup_ids_to_remove_from_curation_concern( env, new_work_ids )
          add_new_work_ids_not_already_in_curation_concern(env, new_work_ids)
          env.curation_concern.errors[:in_works_ids].empty?
        end

        def can_edit_both_works?( env, work )
          env.current_ability.can?( :edit, work ) && env.current_ability.can?( :edit, env.curation_concern )
        end

        def cleanup_ids_to_remove_from_curation_concern( env, new_work_ids )
          (env.curation_concern.in_works_ids - new_work_ids).each do |old_id|
            work = ::PersistHelper.find( old_id )
            Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 "provenance_child_remove",
                                                 "parent.id=#{work_id}",
                                                 "child_id=#{env.curation_concern.id}",
                                                 "child_title=#{env.curation_concern.title}",
                                                 "event_note=BeforeAddToWorkActor",
                                                 "" ] if before_add_to_work_actor_debug_verbose
            next unless work.respond_to? :provenance_child_remove
            work.provenance_child_remove( current_user: env.user,
                                          child_id: env.curation_concern.id,
                                          child_title: env.curation_concern.title,
                                          event_note: 'BeforeAddToWorkActor' )
          end
        end

    end

  end
end
