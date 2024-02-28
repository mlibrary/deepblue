# frozen_string_literal: true

module Umrdr

  module SolrDocumentBehavior

    mattr_accessor :solr_document_behavior_debug_verbose,
                   default: Rails.configuration.solr_document_behavior_debug_verbose

    extend ActiveSupport::Concern

    def access_deepblue 
      fetch('access_deepblue_tesim', [])
    end

    def authoremail
      Array(self['authoremail_tesim']).first
    end

    def checksum_algorithm
      Array(self['checksum_algorithm_tesim']).first
    end

    def checksum_value
      Array(self['checksum_value_tesim']).first
    end

    def creator_orcid
      fetch('creator_orcid_tesim', [])
    end

    def creator_orcid_json
      rv = self['creator_orcid_json_ssim']
      return rv
    end

    def curation_notes_admin
      fetch('curation_notes_admin_tesim', [])
    end

    def curation_notes_user
      fetch('curation_notes_user_tesim', [])
    end

    def depositor_creator
      Array(self['depositor_creator_tesim']).first
    end

    def date_coverage
      Array(self['date_coverage_tesim']).first
    end

    def date_published
      date_published2
    end

    def date_published2
      self[ 'date_published_dtsim' ]
    end

    def description_file_set
      fetch('description_file_set_tesim', []).first
    end

    ## begin DOI methods


    def doi
      rv = self[ 'doi_tesim' ]
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "rv = #{rv}",
      #                                        "" ] if solr_document_behavior_debug_verbose
      return nil unless rv.present?
      return Array( rv ).first
    end

    def doi_minted?
      # the first time this is called, doi will not be in solr.
      doi.present?
    rescue
      nil
    end

    def doi_minting_enabled?
      ::Deepblue::DoiBehavior.doi_minting_enabled
    end

    def doi_pending?
      doi == ::Deepblue::DoiBehavior.doi_pending
    end

    ## end DOI methods

    def file_size
      Array(self['file_size_lts']).first
    end

    def file_size_human_readable
      size = file_size
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( size, precision: 3 )
    end

    def fundedby
      fetch('fundedby_tesim', [])
    end

    def fundedby_other
      fetch('fundedby_other_tesim', [])
    end

    def grantnumber
      Array(self['grantnumber_tesim']).first
    end

    def methodology
      fetch('methodology_tesim', [])
    end

    def original_checksum
      Array(self['original_checksum_tesim']).first
    end

    def prior_identifier
      fetch('prior_identifier_tesim', [])
    end

    def read_me_file_set_id
      rv = self['read_me_file_set_id_tesim']
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "rv = #{rv}",
      #                                        "" ] if solr_document_behavior_debug_verbose
      return Array( rv ).first
    end

    def referenced_by
      fetch('referenced_by_tesim', [])
    end

    def rights_license
      Array(self['rights_license_tesim']).first
    end

    def rights_license_other
      Array(self['rights_license_other_tesim']).first
    end

    def subject_discipline
      fetch('subject_discipline_tesim', [])
    end

    def ticket
      rv = self['ticket_tesim']
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "ticket rv = #{rv}",
      #                                        "" ] if solr_document_behavior_debug_verbose
      rv = Array( rv ).first
      # rv = ::Deepblue::TicketHelper.ticket_status( curation_concern: self, raw_ticket: rv ) if rv.blank?
      return rv
    end

    def tombstone
      Array(self['tombstone_tesim']).first
    end

    def total_file_size
      rv = Array(self['total_file_size_lts']).first
      return 0 if rv.blank?
      rv
    end

    def total_file_size_human_readable
      total = total_file_size
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total, precision: 3 )
    end

    def virus_scan_service
      Array(self['virus_scan_service_tesim']).first
    end

    def virus_scan_status
      Array(self['virus_scan_status_tesim']).first
    end

    def virus_scan_status_date
      Array(self['virus_scan_status_date_tesim']).first
    end

  end

end
