# frozen_string_literal: true

module Deepblue

  class IndexesTotalFileSize
    include Hyrax::IndexesBasicMetadata

    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('total_file_size', Hyrax::FileSetIndexer::STORED_LONG)] = object.size_of_work
      end
    end

  end

end
