# frozen_string_literal: true

module Deepblue

  class AbstractEventError < RuntimeError
  end

  module AbstractEventBehavior

    EVENT_CHARACTERIZE      = 'characterize'.freeze
    EVENT_CHILD_ADD         = 'child_add'.freeze
    EVENT_CHILD_REMOVE      = 'child_remove'.freeze
    EVENT_CREATE            = 'create'.freeze
    EVENT_CREATE_DERIVATIVE = 'create_derivative'.freeze
    EVENT_DESTROY           = 'destroy'.freeze
    EVENT_DOWNLOAD          = 'download'.freeze
    EVENT_EMBARGO           = 'embargo'.freeze
    EVENT_FIXITY_CHECK      = 'fixity_check'.freeze
    EVENT_GLOBUS            = 'globus'.freeze
    EVENT_INGEST            = 'ingest'.freeze
    EVENT_MIGRATE           = 'migrate'.freeze
    EVENT_MINT_DOI          = 'mint_doi'.freeze
    EVENT_PUBLISH           = 'publish'.freeze
    EVENT_TRANSFER          = 'transfer'.freeze
    EVENT_TOMBSTONE         = 'tombstone'.freeze
    EVENT_UNEMBARGO         = 'unembargo'.freeze
    EVENT_UNPUBLISH         = 'unpublish'.freeze
    EVENT_UPDATE            = 'update'.freeze
    EVENT_UPDATE_AFTER      = 'update_after'.freeze
    EVENT_UPDATE_BEFORE     = 'update_before'.freeze
    EVENT_UPDATE_VERSION    = 'update_version'.freeze
    EVENT_UPLOAD            = 'upload'.freeze
    EVENT_VIRUS_SCAN        = 'virus_scan'.freeze
    EVENT_WORKFLOW          = 'workflow'.freeze
    EVENTS                  =
      [
        EVENT_CHARACTERIZE,
        EVENT_CHILD_ADD,
        EVENT_CHILD_REMOVE,
        EVENT_CREATE,
        EVENT_CREATE_DERIVATIVE,
        EVENT_DESTROY,
        EVENT_DOWNLOAD,
        EVENT_EMBARGO,
        EVENT_FIXITY_CHECK,
        EVENT_GLOBUS,
        EVENT_INGEST,
        EVENT_MIGRATE,
        EVENT_MINT_DOI,
        EVENT_PUBLISH,
        EVENT_TRANSFER,
        EVENT_TOMBSTONE,
        EVENT_UNEMBARGO,
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
