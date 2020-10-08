# frozen_string_literal: true

module Deepblue

  module TotalFileSizePresenterBehavior

    # delegate :total_file_size, :total_file_size_human_readable, to: :solr_document

    def total_file_count
      solr_value = @solr_document[Solrizer.solr_name('file_set_ids', :symbol)]
      return 0 if solr_value.blank?
      solr_value.size
    end

    def total_file_size
      solr_value = @solr_document[Solrizer.solr_name('total_file_size', Hyrax::FileSetIndexer::STORED_LONG)]
      return 0 if solr_value.blank?
      solr_value
    end

    def total_file_size_human_readable
      human_readable( total_file_size )
    end

  end

end
