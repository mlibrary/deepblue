module Umrdr
  module SolrDocumentBehavior
    extend ActiveSupport::Concern

    def authoremail
      Array(self[Solrizer.solr_name('authoremail')]).first
    end

    def date_coverage
      Array(self[Solrizer.solr_name('date_coverage')]).first
    end

    def file_size
      Array(self['file_size_lts']).first # standard lookup Solrizer.solr_name('file_size')] produces solr_document['file_size_tesim']
    end

    def file_size_readable
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( file_size, precision: 3 )
    end

    def fundedby
      Array(self[Solrizer.solr_name('fundedby')]).first
    end

    def grantnumber
      Array(self[Solrizer.solr_name('grantnumber')]).first
    end

    def isReferencedBy
      #Array(self[Solrizer.solr_name('isReferencedBy')]).first
      fetch(Solrizer.solr_name('isReferencedBy'), [])
    end

    def methodology
      Array(self[Solrizer.solr_name('methodology')]).first
    end

    def original_checksum
      Array(self[Solrizer.solr_name('original_checksum')]).first
    end

    def tombstone
      Array(self[Solrizer.solr_name('tombstone')]).first
    end

    def total_file_size
      Array(self['total_file_size_lts']).first # standard lookup Solrizer.solr_name('total_file_size')] produces solr_document['file_size_tesim']
    end

    def total_file_size_human_readable
      total = total_file_size
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total, precision: 3 )
    end

  end
end
