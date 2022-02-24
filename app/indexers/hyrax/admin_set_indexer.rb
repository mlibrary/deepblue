module Hyrax
  class AdminSetIndexer < ActiveFedora::IndexingService
    include Hyrax::IndexesThumbnails

    self.thumbnail_path_service = Hyrax::CollectionThumbnailPathService

    def generate_solr_document
      super.tap do |solr_doc|

        # Makes Admin Sets show under the "Admin Sets" tab
        Solrizer.set_field(solr_doc, 'generic_type', 'Admin Set', :facetable)

        # So that title sort can be done ...
        value = Array( object.title ).join( " " )
        solr_doc[Solrizer.solr_name('title', :stored_searchable)] = value
        solr_doc[Solrizer.solr_name('title', :stored_sortable)] = value
      end
    end
  end
end
