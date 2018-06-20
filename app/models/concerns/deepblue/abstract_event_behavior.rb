# frozen_string_literal: true

module Deepblue

  class AbstractEventError < RuntimeError
  end

  module AbstractEventBehavior

    EVENT_CHARACTERIZE      = 'characterize'
    EVENT_CHILD_ADD         = 'child_add'
    EVENT_CHILD_REMOVE      = 'child_remove'
    EVENT_CREATE            = 'create'
    EVENT_CREATE_DERIVATIVE = 'create_derivative'
    EVENT_DESTROY           = 'destroy'
    EVENT_INGEST            = 'ingest'
    EVENT_MINT_DOI          = 'mint_doi'
    EVENT_PUBLISH           = 'publish'
    EVENT_TOMBSTONE         = 'tombstone'
    EVENT_UPDATE            = 'update'
    EVENT_UPDATE_AFTER      = 'update_after'
    EVENT_UPDATE_BEFORE     = 'update_before'
    EVENT_UPLOAD            = 'upload'
    EVENTS                  =
      [
        EVENT_CHARACTERIZE,
        EVENT_CHILD_ADD,
        EVENT_CHILD_REMOVE,
        EVENT_CREATE,
        EVENT_CREATE_DERIVATIVE,
        EVENT_DESTROY,
        EVENT_INGEST,
        EVENT_MINT_DOI,
        EVENT_PUBLISH,
        EVENT_TOMBSTONE,
        EVENT_UPDATE,
        EVENT_UPDATE_AFTER,
        EVENT_UPDATE_BEFORE,
        EVENT_UPLOAD
      ].freeze

    IGNORE_BLANK_KEY_VALUES = true
    USE_BLANK_KEY_VALUES = false

    def event_attributes_cache_exist?( event:, id:, behavior: nil )
      key = event_attributes_cache_key( event: event, id: id, behavior: behavior )
      rv = Rails.cache.exist?( key )
      rv
    end

    def event_attributes_cache_fetch( event:, id:, behavior: nil )
      key = event_attributes_cache_key( event: event, id: id, behavior: behavior )
      rv = Rails.cache.fetch( key )
      rv
    end

    def event_attributes_cache_key( event:, id:, behavior: nil )
      return "#{id}.#{event}" if behavior.nil?
      "#{id}.#{event}.#{behavior}"
    end

    def event_attributes_cache_write( event:, id:, attributes: DateTime.now, behavior: nil )
      key = event_attributes_cache_key( event: event, id: id, behavior: behavior )
      Rails.cache.write( key, attributes )
    end

  end

end
