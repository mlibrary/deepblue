# frozen_string_literal: true

require 'edtf'

module Hyrax

  class DeepblueController < ApplicationController

    include Hyrax::BreadcrumbsForWorks

    def box_enabled?
      false
    end

    def display_provenance_log_enabled?
      false
    end

    def doi_minting_enabled?
      false
    end

    def globus_download_enabled?
      false
    end

    # def mint_doi_enabled?
    #   false
    # end

    def tombstone_enabled?
      false
    end

    def zip_download_enabled?
      false
    end

  end

end
