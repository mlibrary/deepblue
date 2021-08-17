# frozen_string_literal: true

module Hyrax

  module Actors

    class EnvironmentAttributes

      ENVIRONMENT_ATTRIBUTES_DEBUG_VERBOSE = false

      # IGNORE_KEYS = [].freeze
      LOG_IT = false
      IGNORE_KEYS = [ :visibility ].freeze

      instance_methods.each do |m|
        undef_method(m) unless m =~ /(^__|^nil\?|^send$|^object_id$)/
      end

      attr_reader :curation_concern_id

      def initialize( hash, curation_concern_id: '' )
        @hash = hash
        @curation_concern_id = curation_concern_id
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                            "curation_concern_id=#{@curation_concern_id}",
                                            "EnvironmentAttributes.initialized",
                                            "attributes=#{@hash}" ] if ENVIRONMENT_ATTRIBUTES_DEBUG_VERBOSE
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
          return unless LOG_IT
          return if IGNORE_KEYS.include? key
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                               "called from: #{caller_locations(1, 3)[2]}",
                                              "curation_concern_id=#{@curation_concern_id}",
                                              "#{key_label} key=#{key}",
                                              "attributes=#{@hash}" ] if ENVIRONMENT_ATTRIBUTES_DEBUG_VERBOSE
        rescue Exception => e # rubocop:disable Lint/RescueException
          Rails.logger.error "log_it exception - #{e.class}: #{e.message} at #{e.backtrace[0]}"
        end

        def method_missing( method, *args, &block )
          @hash.send(method, *args, &block)
        end

    end

  end

end
