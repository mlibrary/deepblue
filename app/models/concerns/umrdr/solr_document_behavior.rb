# frozen_string_literal: true

module Umrdr
  module SolrDocumentBehavior
    extend ActiveSupport::Concern

    def authoremail
      Array(self[Solrizer.solr_name('authoremail')]).first
    end

    def curation_notes_admin
      fetch(Solrizer.solr_name('curation_notes_admin'), [])
    end

    def curation_notes_user
      fetch(Solrizer.solr_name('curation_notes_user'), [])
    end

    def date_coverage
      Array(self[Solrizer.solr_name('date_coverage')]).first
    end

    def doi
      Array(self[Solrizer.solr_name('doi')]).first
    end

    def file_size
      Array(self['file_size_lts']).first # standard lookup Solrizer.solr_name('file_size')] produces solr_document['file_size_tesim']
    end

    def file_size_human_readable
      size = file_size
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( size, precision: 3 )
    end

    def fundedby
      fetch(Solrizer.solr_name('fundedby'), [])
    end

    def fundedby_other
      Array(self[Solrizer.solr_name('fundedby_other')]).first
    end

    def grantnumber
      Array(self[Solrizer.solr_name('grantnumber')]).first
    end

    def methodology
      Array(self[Solrizer.solr_name('methodology')]).first
    end

    def original_checksum
      Array(self[Solrizer.solr_name('original_checksum')]).first
    end

    def referenced_by
      # Array(self[Solrizer.solr_name('referenced_by')]).first
      fetch(Solrizer.solr_name('referenced_by'), [])
    end

    def rights_license_other
      Array(self[Solrizer.solr_name('rights_license_other')]).first
    end

    def subject_discipline
      fetch(Solrizer.solr_name('subject_discipline'), [])
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
