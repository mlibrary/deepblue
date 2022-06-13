# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../app/services/deepblue/doi_minting_service'

module Deepblue

  class EnsureDoiMintedTask < AbstractTask

    def initialize( id:, options: {} )
      @id = id
      super( options: options )
    end

    def run
      DoiMintingService.ensure_doi_minted( id: @id,
                                           msg_handler: msg_handler,
                                           task: true,
                                           debug_verbose: false )
    end

  end

end
