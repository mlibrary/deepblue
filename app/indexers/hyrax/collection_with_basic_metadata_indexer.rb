# frozen_string_literal: true

module Hyrax
  class CollectionWithBasicMetadataIndexer < CollectionIndexer
    include Hyrax::IndexesBasicMetadata

    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('creator_ordered', :stored_searchable)] = object.creator_ordered
      end
    end

  end
end
