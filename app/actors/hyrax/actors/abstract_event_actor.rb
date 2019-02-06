# frozen_string_literal: true

module Hyrax
  module Actors

    class AbstractEventActor < Hyrax::Actors::AbstractActor

      # LOG_IGNORE_EVENT = [].freeze

      protected

        def attributes_blank?( attributes )
          return true if attributes.blank?
          return true if [nil] == attributes
          false
        end

        # def log_event( env: )
        #   # return if LOG_IGNORE_EVENT.include? key
        #   actor = next_actor
        #   from = caller_locations(1, 2)[1]
        #   Deepblue::LoggingHelper.bold_debug ["from #{from}",
        #                                       "env.curation_concern.class.name=#{env.curation_concern.class.name}",
        #                                       "env.curation_concern.id=#{env.curation_concern&.id}",
        #                                       "next_actor=#{next_actor.class.name}",
        #                                       "env.attributes=#{env.attributes}" ]
        # rescue Exception => e # rubocop:disable Lint/RescueException
        #   Rails.logger.error "log_event exception - #{e.class}: #{e.message} at #{e.backtrace[0]}"
        # end

    end

  end
end
