module Dataset
  class FileSetPresenter < ::Hyrax::FileSetPresenter

    delegate :file_size, :file_size_readable, :original_checksum, :mime_type, to: :solr_document

    def identifiers_minted?(identifier)
      #the first time this is called, doi will not be solr.
      begin
        @solr_document[Solrizer.solr_name('doi', :symbol)].first
      rescue
        nil
      end
    end

    def identifiers_pending?(identifier)
      @solr_document[Solrizer.solr_name('doi', :symbol)].first == GenericWork::PENDING
    end

  	def parent_doi?
  		g =GenericWork.find (self.parent.id)
  		g.doi.present?
    end

    def parent_public?
  		g =GenericWork.find (self.parent.id)
  		g.public?
    end

  end
end
