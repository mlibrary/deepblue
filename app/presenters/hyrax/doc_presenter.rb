# Generated via
#  `rails generate hyrax:work Doc`
module Hyrax
  class DocPresenter < DeepbluePresenter

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

    :other_affiliation,
    :contributor_affiliationumcampus,
    :academic_affiliation,
    :alt_title,
    :identifier_source,
    :publisher,
    :relation_ispartofseries,
    :description_sponsorship,
    :identifier_citedreference,
    :peerreviewed,
    :subject_hlbtoplevel,
    :subject_hlbsecondlevel,

               :type_none,
               :identifier_other,
               :subject,
               :identifier_uri,
              to: :solr_document


  end
end
