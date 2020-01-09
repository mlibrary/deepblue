# frozen_string_literal: true

module Umrdr

  module SolrDocumentBehavior
    extend ActiveSupport::Concern

    def access_deepblue 
      fetch(Solrizer.solr_name('access_deepblue'), [])
    end

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

    def date_published
      date_published2
    end

    def date_published2
      self[ 'date_published_dtsim' ]
    end

    ## begin DOI methods

    def doi
      rv = doi_the_correct_one
      # rv = Array( self[ Solrizer.solr_name( 'doi', :symbol ) ] ).first
      # rv = self[ Solrizer.solr_name( 'doi', :symbol ) ]
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "doi = #{doi}",
      #                                        "" ]
      return rv
    end

    def doi_the_correct_one
      # rv = Array( self[Solrizer.solr_name('doi')] ).first
      rv = self[ Solrizer.solr_name( 'doi', :symbol ) ]
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "doi = #{doi}",
      #                                        "" ]
      return rv
    end

    def doi_minted?
      # the first time this is called, doi will not be in solr.
      # @solr_document[ Solrizer.solr_name( 'doi', :symbol ) ].first
      doi_the_correct_one.present?
    rescue
      nil
    end

    def doi_minting_enabled?
      ::Deepblue::DoiBehavior::DOI_MINTING_ENABLED
    end

    def doi_pending?
      #@solr_document[ Solrizer.solr_name( 'doi', :symbol ) ].first == ::Deepblue::DoiBehavior::DOI_PENDING
      doi_the_correct_one == ::Deepblue::DoiBehavior::DOI_PENDING
    end

    ## end DOI methods

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
      #Array(self[Solrizer.solr_name('methodology')]).first
      fetch(Solrizer.solr_name('methodology'), [])
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

    def virus_scan_service
      Array(self[Solrizer.solr_name('virus_scan_service')]).first
    end

    def virus_scan_status
      Array(self[Solrizer.solr_name('virus_scan_status')]).first
    end

    def virus_scan_status_date
      Array(self[Solrizer.solr_name('virus_scan_status_date')]).first
    end

  end

end
