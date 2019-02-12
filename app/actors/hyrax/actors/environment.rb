# frozen_string_literal: true

module Hyrax

  module Actors

    class EnvironmentAttributes

      # IGNORE_KEYS = [].freeze
      IGNORE_KEYS = [ :visibility ].freeze

      instance_methods.each do |m|
        undef_method(m) unless m =~ /(^__|^nil\?|^send$|^object_id$)/
      end

      attr_reader :curation_concern_id

      def initialize( hash, curation_concern_id: '' )
        @hash = hash
        @curation_concern_id = curation_concern_id
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                            Deepblue::LoggingHelper.called_from,
                                            "curation_concern_id=#{@curation_concern_id}",
                                            "EnvironmentAttributes.initialized",
                                            "attributes=#{@hash}" ]
      end

      def respond_to?( symbol, include_priv=false )
        @hash.respond_to?( symbol, include_priv )
      end

      def []( key )
        log_it( "[key]", key )
        @hash[ key ]
      end

      def delete( key )
        log_it( "delete", key )
        @hash.delete( key )
      end

      def values_at( key )
        log_it( "values_at", key )
        @hash.values_at( key )
      end

      private

        def log_it( key_label, key )
          return if IGNORE_KEYS.include? key
          from = caller_locations(1, 2)[1]
          Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                              "curation_concern_id=#{@curation_concern_id}",
                                              "#{key_label} key=#{key}",
                                              "attributes=#{@hash}" ]
        rescue Exception => e # rubocop:disable Lint/RescueException
          Rails.logger.error "log_it exception - #{e.class}: #{e.message} at #{e.backtrace[0]}"
        end

        def method_missing( method, *args, &block )
          @hash.send(method, *args, &block)
        end

    end

    class Environment
      # @param [ActiveFedora::Base] curation_concern work to operate on
      # @param [Ability] current_ability the authorizations of the acting user
      # @param [ActionController::Parameters] attributes user provided form attributes
      def initialize(curation_concern, current_ability, attributes)
        @curation_concern = curation_concern
        @current_ability = current_ability
        # @attributes = attributes.to_h.with_indifferent_access
        @attributes = EnvironmentAttributes.new( attributes.to_h.with_indifferent_access,
                                                 curation_concern_id: curation_concern&.id )
      end

      attr_reader :curation_concern, :current_ability, :attributes

      # @return [User] the user from the current_ability
      def user
        current_ability.current_user
      end

      def log_event( next_actor: )
        # return if LOG_IGNORE_EVENT.include? key
        from = caller_locations(1, 2)[1]
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                            "curation_concern.class.name=#{curation_concern.class.name}",
                                            "curation_concern.id=#{curation_concern&.id}",
                                             Deepblue::LoggingHelper.obj_class( "next_actor", next_actor ),
                                            "attributes=#{attributes}" ]
      rescue Exception => e # rubocop:disable Lint/RescueException
        Rails.logger.error "log_event exception - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

    end

  end

end
