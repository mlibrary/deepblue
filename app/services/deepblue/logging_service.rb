# frozen_string_literal: true

module Deepblue

  class LoggingService

    attr_reader :event_name

    def initialize( event_name: )
      @event_name = event_name
      ActiveSupport::Notifications.subscribe @event_name do |*args|
        process_event( *args )
      end
    end

    def process_event( *args )
      Rails.logger.debug ">>>>> #{@event_name} >>>>>"
      Rails.logger.debug ">>>>> #{@event_name} >>>>>"
      Rails.logger.debug "#{@event_name} >>>>> #{args.extract_options!}"
      Rails.logger.debug ">>>>> #{@event_name} >>>>>"
      Rails.logger.debug ">>>>> #{@event_name} >>>>>"
    end

  end

end