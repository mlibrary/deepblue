# frozen_string_literal: true

require_relative './environment_attributes'

module Hyrax

  module Actors

    # class EnvironmentAttributes
    #
    #   ENVIRONMENT_ATTRIBUTES_VERBOSE = false
    #
    #   # IGNORE_KEYS = [].freeze
    #   LOG_IT = false
    #   IGNORE_KEYS = [ :visibility ].freeze
    #
    #   instance_methods.each do |m|
    #     undef_method(m) unless m =~ /(^__|^nil\?|^send$|^object_id$)/
    #   end
    #
    #   attr_reader :curation_concern_id
    #
    #   def initialize( hash, curation_concern_id: '' )
    #     @hash = hash
    #     @curation_concern_id = curation_concern_id
    #     Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
    #                                         Deepblue::LoggingHelper.called_from,
    #                                         "curation_concern_id=#{@curation_concern_id}",
    #                                         "EnvironmentAttributes.initialized",
    #                                         "attributes=#{@hash}" ] if ENVIRONMENT_ATTRIBUTES_VERBOSE
    #   end
    #
    #   def respond_to?( symbol, include_priv=false )
    #     @hash.respond_to?( symbol, include_priv )
    #   end
    #
    #   def []( key )
    #     log_it( "[key]", key )
    #     @hash[ key ]
    #   end
    #
    #   def delete( key )
    #     log_it( "delete", key )
    #     @hash.delete( key )
    #   end
    #
    #   def values_at( key )
    #     log_it( "values_at", key )
    #     @hash.values_at( key )
    #   end
    #
    #   private
    #
    #     def log_it( key_label, key )
    #       return unless LOG_IT
    #       return if IGNORE_KEYS.include? key
    #       Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
    #                                            Deepblue::LoggingHelper.called_from,
    #                                            "called from: #{caller_locations(1, 3)[2]}",
    #                                           "curation_concern_id=#{@curation_concern_id}",
    #                                           "#{key_label} key=#{key}",
    #                                           "attributes=#{@hash}" ] if ENVIRONMENT_ATTRIBUTES_VERBOSE
    #     rescue Exception => e # rubocop:disable Lint/RescueException
    #       Rails.logger.error "log_it exception - #{e.class}: #{e.message} at #{e.backtrace[0]}"
    #     end
    #
    #     def method_missing( method, *args, &block )
    #       @hash.send(method, *args, &block)
    #     end
    #
    # end

    class Environment

      # @param [ActiveFedora::Base] curation_concern work to operate on
      # @param [Ability] current_ability the authorizations of the acting user
      # @param [ActionController::Parameters] attributes user provided form attributes
      def initialize( curation_concern, current_ability, attributes )
        @curation_concern = curation_concern
        @current_ability = current_ability
        @attributes = attributes
        @attributes = attributes.to_h.with_indifferent_access unless attributes.is_a? EnvironmentAttributes
      end

      attr_reader :curation_concern, :current_ability, :attributes

      # @return [User] the user from the current_ability
      def user
        current_ability.current_user
      end

    end

    # class EnvironmentEnhanced < Environment
    #
    #   ENVIRONMENT_ENHANCED_DEBUG_VERBOSE = false
    #
    #   # @param [ActiveFedora::Base] curation_concern work to operate on
    #   # @param [Ability] current_ability the authorizations of the acting user
    #   # @param [ActionController::Parameters] attributes user provided form attributes
    #   def initialize( curation_concern:, current_ability:, attributes:, action:, wants_format: )
    #
    #     super( curation_concern,
    #            current_ability,
    #            EnvironmentAttributes.new( attributes.to_h.with_indifferent_access,
    #                                       curation_concern_id: curation_concern&.id ) )
    #     ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
    #                                            Deepblue::LoggingHelper.called_from,
    #                                            "curation_concern=#{curation_concern}",
    #                                            "current_ability=#{current_ability}",
    #                                            "attributes.class.name=#{attributes.class.name}",
    #                                            "attributes=#{attributes}",
    #                                            "action=#{action}",
    #                                            "wants_format=#{wants_format}",
    #                                            "" ] if ENVIRONMENT_ENHANCED_DEBUG_VERBOSE
    #     @action = action
    #     @wants_format = wants_format
    #   end
    #
    #   attr_accessor :action, :wants_format
    #
    #   def log_event( next_actor: )
    #     # return if LOG_IGNORE_EVENT.include? key
    #     from = caller_locations(1, 2)[1]
    #     ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
    #                                            Deepblue::LoggingHelper.called_from,
    #                                            "curation_concern.class.name=#{curation_concern.class.name}",
    #                                            "curation_concern.id=#{curation_concern&.id}",
    #                                            Deepblue::LoggingHelper.obj_class( "next_actor", next_actor ),
    #                                            "attributes=#{attributes}" ] if ENVIRONMENT_ENHANCED_DEBUG_VERBOSE
    #   rescue Exception => e # rubocop:disable Lint/RescueException
    #     Rails.logger.error "log_event exception - #{e.class}: #{e.message} at #{e.backtrace[0]}"
    #   end
    #
    #   def clone_with_new( attributes: )
    #     ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
    #                                            Deepblue::LoggingHelper.called_from,
    #                                            "curation_concern=#{curation_concern}",
    #                                            "current_ability=#{current_ability}",
    #                                            "attributes=#{attributes}",
    #                                            "@action=#{@action}",
    #                                            "@wants_format=#{@wants_format}",
    #                                            "" ] if ENVIRONMENT_ENHANCED_DEBUG_VERBOSE
    #     EnvironmentEnhanced.new( curation_concern: curation_concern,
    #                              current_ability: current_ability,
    #                              attributes: attributes,
    #                              action: @action,
    #                              wants_format: @wants_format )
    #   end
    #
    # end

  end

end
