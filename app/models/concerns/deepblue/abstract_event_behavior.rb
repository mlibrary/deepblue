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
    EVENT_DOWNLOAD          = 'download'
    EVENT_FIXITY_CHECK      = 'fixity_check'
    EVENT_GLOBUS            = 'globus'
    EVENT_INGEST            = 'ingest'
    EVENT_MIGRATE           = 'migrate'
    EVENT_MINT_DOI          = 'mint_doi'
    EVENT_PUBLISH           = 'publish'
    EVENT_TOMBSTONE         = 'tombstone'
    EVENT_UNPUBLISH         = 'unpublish'
    EVENT_UPDATE            = 'update'
    EVENT_UPDATE_AFTER      = 'update_after'
    EVENT_UPDATE_BEFORE     = 'update_before'
    EVENT_UPDATE_VERSION    = 'update_version'
    EVENT_UPLOAD            = 'upload'
    EVENT_VIRUS_SCAN        = 'virus_scan'
    EVENT_WORKFLOW          = 'workflow'
    EVENTS                  =
      [
        EVENT_CHARACTERIZE,
        EVENT_CHILD_ADD,
        EVENT_CHILD_REMOVE,
        EVENT_CREATE,
        EVENT_CREATE_DERIVATIVE,
        EVENT_DESTROY,
        EVENT_DOWNLOAD,
        EVENT_FIXITY_CHECK,
        EVENT_GLOBUS,
        EVENT_INGEST,
        EVENT_MIGRATE,
        EVENT_MINT_DOI,
        EVENT_PUBLISH,
        EVENT_TOMBSTONE,
        EVENT_UNPUBLISH,
        EVENT_UPDATE,
        EVENT_UPDATE_AFTER,
        EVENT_UPDATE_BEFORE,
        EVENT_UPDATE_VERSION,
        EVENT_UPLOAD,
        EVENT_VIRUS_SCAN,
        EVENT_WORKFLOW
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
      return "#{id}.#{event}" if behavior.blank?
      "#{id}.#{event}.#{behavior}"
    end

    def event_attributes_cache_write( event:, id:, attributes: DateTime.now, behavior: nil )
      key = event_attributes_cache_key( event: event, id: id, behavior: behavior )
      Rails.cache.write( key, attributes )
    end

  end

end
