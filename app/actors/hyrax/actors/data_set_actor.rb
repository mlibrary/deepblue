# frozen_string_literal: true

module Hyrax
  module Actors

    class DataSetActor < Hyrax::Actors::BaseActor

      DATA_SET_ACTOR_DEBUG_VERBOSE = false

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
                                               "" ] if DATA_SET_ACTOR_DEBUG_VERBOSE
        clean_attrs = clean_attributes(env.attributes)
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "env.action=#{env.action}",
                                               "env.wants_format=#{env.wants_format}",
                                               "clean_attrs=#{clean_attrs}",
                                               "" ] if DATA_SET_ACTOR_DEBUG_VERBOSE
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
                                               "env.attributes.class.name=#{env.attributes.class.name}",
                                               "env.attributes=#{env.attributes}",
                                               "env.action=#{env.action}",
                                               "env.wants_format=#{env.wants_format}",
                                               "" ] if DATA_SET_ACTOR_DEBUG_VERBOSE
        return false if env.curation_concern.errors.present?
        valid = true
        attributes = env.attributes
        curation_concern = env.curation_concern
        primary_attributes.each do |attr|
          key = attr.to_s
          ::Deepblue::LoggingHelper.debug [ "curation_concern[#{attr}].class.name - attributes[{key}]=#{curation_concern[key].class.name} - #{attributes[key]}"
                                          ] if DATA_SET_ACTOR_DEBUG_VERBOSE
          next unless attributes.key?( key )
          value = attributes[key]
          case curation_concern[attr].class
          when Array
            next if value.is_a? Array
            curation_concern.errors.add( :create, "not an array: #{key}" )
            valid = false
          when String
            next if value.is_a? Array
            curation_concern.errors.add( :create, "not a string: #{key}" )
            valid = false
          else
            # TODO
          end
        end
        case env.action.to_s
        when "create"
          ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 "env.action=#{env.action}",
                                                 ""
                                                ] if DATA_SET_ACTOR_DEBUG_VERBOSE
          required_attributes.each do |attr|
            key = attr.to_s
            ::Deepblue::LoggingHelper.debug [ "curation_concern[#{attr}].class.name - attributes[{key}]=#{curation_concern[key].class.name} - #{attributes[key]}"
                                            ] if DATA_SET_ACTOR_DEBUG_VERBOSE
            next unless attributes.key? attr
            curation_concern.errors.add( :create, "required field missing: #{attr}" )
            valid = false
          end
        when "update"
          ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 "env.action=#{env.action}",
                                                 ""
                                               ] if DATA_SET_ACTOR_DEBUG_VERBOSE
          # for testing purposes, prevent updates to title
          required_attributes.each do |attr|
            key = attr.to_s
            ::Deepblue::LoggingHelper.debug [ "curation_concern[#{attr}].class.name - attributes[{key}]=#{curation_concern[key].class.name} - #{attributes[key]}"
                                            ] if DATA_SET_ACTOR_DEBUG_VERBOSE
            # check if this will remove the attribute
          end
        end
        return valid
      end

    end

  end
end
