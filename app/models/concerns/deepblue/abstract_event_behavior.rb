# frozen_string_literal: true

module Deepblue

  class AbstractEventError < RuntimeError
  end

  module AbstractEventBehavior

    EVENT_CHARACTERIZE      = 'characterize'.freeze      unless const_defined? :EVENT_CHARACTERIZE
    EVENT_CHILD_ADD         = 'child_add'.freeze         unless const_defined? :EVENT_CHILD_ADD
    EVENT_CHILD_REMOVE      = 'child_remove'.freeze      unless const_defined? :EVENT_CHILD_REMOVE
    EVENT_CREATE            = 'create'.freeze            unless const_defined? :EVENT_CREATE
    EVENT_CREATE_DERIVATIVE = 'create_derivative'.freeze unless const_defined? :EVENT_CREATE_DERIVATIVE
    EVENT_DESTROY           = 'destroy'.freeze           unless const_defined? :EVENT_DESTROY
    EVENT_DOWNLOAD          = 'download'.freeze          unless const_defined? :EVENT_DOWNLOAD
    EVENT_EMBARGO           = 'embargo'.freeze           unless const_defined? :EVENT_EMBARGO
    EVENT_FIXITY_CHECK      = 'fixity_check'.freeze      unless const_defined? :EVENT_FIXITY_CHECK
    EVENT_GLOBUS            = 'globus'.freeze            unless const_defined? :EVENT_GLOBUS
    EVENT_INGEST            = 'ingest'.freeze            unless const_defined? :EVENT_INGEST
    EVENT_MIGRATE           = 'migrate'.freeze           unless const_defined? :EVENT_MIGRATE
    EVENT_MINT_DOI          = 'mint_doi'.freeze          unless const_defined? :EVENT_MINT_DOI
    EVENT_PUBLISH           = 'publish'.freeze           unless const_defined? :EVENT_PUBLISH
    EVENT_TRANSFER          = 'transfer'.freeze          unless const_defined? :EVENT_TRANSFER
    EVENT_TOMBSTONE         = 'tombstone'.freeze         unless const_defined? :EVENT_TOMBSTONE
    EVENT_UNEMBARGO         = 'unembargo'.freeze         unless const_defined? :EVENT_UNEMBARGO
    EVENT_UNPUBLISH         = 'unpublish'.freeze         unless const_defined? :EVENT_UNPUBLISH
    EVENT_UPDATE            = 'update'.freeze            unless const_defined? :EVENT_UPDATE
    EVENT_UPDATE_AFTER      = 'update_after'.freeze      unless const_defined? :EVENT_UPDATE_AFTER
    EVENT_UPDATE_BEFORE     = 'update_before'.freeze     unless const_defined? :EVENT_UPDATE_BEFORE
    EVENT_UPDATE_VERSION    = 'update_version'.freeze    unless const_defined? :EVENT_UPDATE_VERSION
    EVENT_UPLOAD            = 'upload'.freeze            unless const_defined? :EVENT_UPLOAD
    EVENT_VIRUS_SCAN        = 'virus_scan'.freeze        unless const_defined? :EVENT_VIRUS_SCAN
    EVENT_WORKFLOW          = 'workflow'.freeze          unless const_defined? :EVENT_WORKFLOW
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
      ].freeze unless const_defined? :EVENT

    IGNORE_BLANK_KEY_VALUES = true.freeze unless const_defined? :IGNORE_BLANK_KEY_VALUES
    USE_BLANK_KEY_VALUES = false.freeze   unless const_defined? :USE_BLANK_KEY_VALUES

    def event_attributes_cache_exist?( event:, id:, behavior: nil )
      ::Deepblue::CacheService.event_attributes_cache_exist?( event: event, id: id, behavior: behavior )
    end

    def event_attributes_cache_fetch( event:, id:, behavior: nil )
      ::Deepblue::CacheService.event_attributes_cache_fetch( event: event, id: id, behavior: behavior )
    end

    def event_attributes_cache_key( event:, id:, behavior: nil )
      ::Deepblue::CacheService.event_attributes_cache_key( event: event, id: id, behavior: behavior )
    end

    def event_attributes_cache_write( event:, id:, attributes: DateTime.now, behavior: nil )
      ::Deepblue::CacheService.event_attributes_cache_write( event: event, id: id, attributes: attributes, behavior: behavior )
    end

  end

end
