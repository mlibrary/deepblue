# frozen_string_literal: true

module Hyrax
  module Actors

    class DataSetActor < Hyrax::Actors::BaseActor

      DATA_SET_ACTOR_VERBOSE = true

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def create(env)
        super(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        super(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        return false unless env.curation_concern
        super(env)
      end

      def apply_save_data_to_curation_concern( env )
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               Deepblue::LoggingHelper.obj_class( 'class', self ),
                                               "env=#{env}",
                                               "env.attributes=#{env.attributes}",
                                               "env.action=#{env.action}",
                                               "env.wants_format=#{env.wants_format}",
                                               "" ] if DATA_SET_ACTOR_VERBOSE
        clean_attrs = clean_attributes(env.attributes)
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "env.action=#{env.action}",
                                               "env.wants_format=#{env.wants_format}",
                                               "clean_attrs=#{clean_attrs}",
                                               "" ] if DATA_SET_ACTOR_VERBOSE
        if 'json' == env.wants_format
          return false unless valid_save_data( env )
        end
        env.curation_concern.attributes = clean_attrs
        env.curation_concern.date_modified = TimeService.time_in_utc
        return true
      end

      # Cast any singular values from the form to multiple values for persistence
      def clean_attributes(attributes)
        # attributes[:rights_license] = Array(attributes[:rights_license]) if attributes.key? :rights_license
        super( attributes )
      end

      def primary_attributes
        DataSetForm.default_work_primary_terms
      end

      def required_attributes
        DataSetForm.required_fields
      end

      def valid_save_data( env )
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               Deepblue::LoggingHelper.obj_class( 'class', self ),
                                               "env=#{env}",
                                               "env.attributes=#{env.attributes}",
                                               "env.action=#{env.action}",
                                               "env.wants_format=#{env.wants_format}",
                                               "" ] if DATA_SET_ACTOR_VERBOSE
        attributes = env.attributes
        # for testing purposes, prevent updates to title
        if env.action.to_s == "update" && attributes.key?( :title )
          ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 Deepblue::LoggingHelper.obj_class( 'class', self ),
                                                 "for testing purposes, prevent updates to title",
                                                 "" ] if DATA_SET_ACTOR_VERBOSE
          env.curation_concern.errors.add( :update, "for testing purposes, prevent updates to title" )
          return false
        elsif env.action == :create
          # TODO test for all required fields
        end
        return true
      end

    end

  end
end
