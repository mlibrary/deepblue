# frozen_string_literal: true

module Hyrax

  module Actors

     class EnvironmentEnhanced < Environment

      ENVIRONMENT_ENHANCED_DEBUG_VERBOSE = false

      # @param [ActiveFedora::Base] curation_concern work to operate on
      # @param [Ability] current_ability the authorizations of the acting user
      # @param [ActionController::Parameters] attributes user provided form attributes
      def initialize( curation_concern:, current_ability:, attributes:, action:, wants_format: )

        super( curation_concern,
               current_ability,
               EnvironmentAttributes.new( attributes.to_h.with_indifferent_access,
                                          curation_concern_id: curation_concern&.id ) )
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "curation_concern=#{curation_concern}",
                                               "current_ability=#{current_ability}",
                                               "attributes.class.name=#{attributes.class.name}",
                                               "attributes=#{attributes}",
                                               "action=#{action}",
                                               "wants_format=#{wants_format}",
                                               "" ] if ENVIRONMENT_ENHANCED_DEBUG_VERBOSE
        @action = action
        @wants_format = wants_format
      end

      attr_accessor :action, :wants_format

      def log_event( next_actor: )
        # return if LOG_IGNORE_EVENT.include? key
        from = caller_locations(1, 2)[1]
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "curation_concern.class.name=#{curation_concern.class.name}",
                                               "curation_concern.id=#{curation_concern&.id}",
                                               Deepblue::LoggingHelper.obj_class( "next_actor", next_actor ),
                                               "attributes=#{attributes}" ] if ENVIRONMENT_ENHANCED_DEBUG_VERBOSE
      rescue Exception => e # rubocop:disable Lint/RescueException
        Rails.logger.error "log_event exception - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def clone_with_new( attributes: )
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "curation_concern=#{curation_concern}",
                                               "current_ability=#{current_ability}",
                                               "attributes=#{attributes}",
                                               "@action=#{@action}",
                                               "@wants_format=#{@wants_format}",
                                               "" ] if ENVIRONMENT_ENHANCED_DEBUG_VERBOSE
        EnvironmentEnhanced.new( curation_concern: curation_concern,
                                 current_ability: current_ability,
                                 attributes: attributes,
                                 action: @action,
                                 wants_format: @wants_format )
      end

    end


  end

end
