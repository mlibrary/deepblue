# frozen_string_literal: true
# Reviewed: hyrax4

module Hyrax
  class CollectionWithBasicMetadataIndexer < CollectionIndexer
    include Hyrax::IndexesBasicMetadata

    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc['creator_ordered_tesim'] = object.creator_ordered
      end
    end

  end
end
