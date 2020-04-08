# frozen_string_literal: true

module Hyrax

  class DeepbluePresenter < Hyrax::WorkShowPresenter

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

    def human_readable_type
      "Work"
    end

    # def mint_doi_enabled?
    #   false
    # end

    # def tombstone_enabled?
    #   false
    # end

    def zip_download_enabled?
      false
    end

    def member_presenter_factory
      MemberPresenterFactory.new(solr_document, current_ability, request)
    end

  end

end
