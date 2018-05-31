# Generated via
#  `rails generate hyrax:work GenericWork`
module Hyrax
  class GenericWorkPresenter < Hyrax::WorkShowPresenter

    delegate  :identifier_orcid, :academic_affiliation, :other_affiliation, :contributor_affiliationumcampus, :alt_title, :date_issued, :identifier_source,  :peerreviewed, :bibliographic_citation, :relation_ispartofseries,  :rights_statement, :type_none, :language_none, :description_mapping,  :description_abstract, :description_sponsorship, :description, to: :solr_document 


  end
end
