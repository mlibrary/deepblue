# frozen_string_literal: true

module Hyrax

  class DsFileSetPresenter < Hyrax::FileSetPresenter

    delegate :file_size, :file_size_readable, :original_checksum, :mime_type, to: :solr_document

    def doi_minted?
      # the first time this is called, doi will not be in solr.
      @solr_document[ Solrizer.solr_name( 'doi', :symbol ) ].first
    rescue
      nil
    end

    def doi_pending?
      @solr_document[ Solrizer.solr_name( 'doi', :symbol ) ].first == DataSet::DOI_PENDING
    end

    def parent_doi?
      g = DataSet.find parent.id
      g.doi.present?
    end

    def parent_public?
      g = DataSet.find parent.id
      g.public?
    end

  end

end
