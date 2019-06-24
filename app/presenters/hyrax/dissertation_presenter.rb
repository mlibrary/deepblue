# frozen_string_literal: true

module Hyrax
  class DissertationPresenter < DeepbluePresenter


    delegate  :authoremail,
              :curation_notes_admin,
              :curation_notes_user,
              :date_coverage,
              :doi, :doi_the_correct_one,
              :doi_minted?,
              :doi_minting_enabled?,
              :doi_pending?,
              :fundedby,
              :fundedby_other,
              :grantnumber,
              :methodology,
              :prior_identifier,
              :referenced_by,
              :rights_license,
              :rights_license_other,
              :description_abstract,
              :subject_discipline,
              :total_file_size,
               :type_none,
               :identifier_other,
               :subject,
               :identifier_uri,
              to: :solr_document

  end
end
