# frozen_string_literal: true

module Hyrax

  # Presents embargoed objects
  class EmbargoPresenter
    include ModelProxy
    attr_accessor :solr_document

    delegate :visibility, :to_s, to: :solr_document

    def human_readable_type
      hrt = solr_document.human_readable_type
      hrt = "Work" if hrt == "Data Set"
      hrt
    end

    # @param [SolrDocument] solr_document
    def initialize(solr_document)
      @solr_document = solr_document
    end

    def embargo_depostor
      solr_document.fetch('depositor_ssim', []).first
    end

    def embargo_release_date
      date = solr_document.embargo_release_date
      return date if date.blank?
      date.to_formatted_s(:rfc822)
    end

    def visibility_after_embargo
      solr_document.fetch('visibility_after_embargo_ssim', []).first
    end

    def embargo_history
      solr_document['embargo_history_ssim']
    end

  end

end
