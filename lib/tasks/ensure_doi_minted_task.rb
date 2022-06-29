# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../app/services/deepblue/doi_minting_service'

module Deepblue

  class EnsureDoiMintedTask < AbstractTask

    attr_accessor :id

    def initialize( id:, options: {} )
      @id = id
      super( options: options )
    end

    def run
      DoiMintingService.ensure_doi_minted( id: @id, msg_handler: msg_handler )
    end

  end

end
