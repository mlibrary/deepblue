module Umrdr
  class FileSetPresenter < ::Hyrax::FileSetPresenter

    delegate :file_size, :file_size_readable, :mime_type, :original_checksum, to: :solr_document

    def identifiers_minted?(identifier)
      #the first time this is called, doi will not be in solr.
      begin
        @solr_document[Solrizer.solr_name('doi', :symbol)].first
      rescue
        nil
      end
    end

    def identifiers_pending?(identifier)
      @solr_document[Solrizer.solr_name('doi', :symbol)].first == UmrdrWork::PENDING
    end

  	def parent_doi?
  		g =UmrdrWork.find (self.parent.id)
  		g.doi.present?
    end

    def parent_public?
  		g =UmrdrWork.find (self.parent.id)
  		g.public?
    end

  end
end
