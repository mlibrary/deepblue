# frozen_string_literal: true

module Deepblue

  class AbstractEventError < RuntimeError
  end

  module AbstractEventBehavior

    EVENT_ADD               = 'add'
    EVENT_CHARACTERIZE      = 'characterize'
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
        EVENT_ADD,
        EVENT_CHARACTERIZE,
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

  end

end
