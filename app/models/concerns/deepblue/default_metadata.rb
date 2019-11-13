# frozen_string_literal: true

module Deepblue

  module DefaultMetadata
    extend ActiveSupport::Concern

    # Usage notes and expectations can be found in the Metadata Application Profile:
    #   https://docs.google.com/spreadsheets/d/1koKjV7bjn7v4r5a3gsowEimljHiAwbwuOgjHe7FEtuw/edit?usp=sharing

    included do # rubocop:disable Metrics/BlockLength

      after_initialize :set_default_visibility

      property :deduplication_key, predicate: "http://curationexperts.com/vocab/predicates#deduplicationKey", multiple: false do |index|
        index.as :stored_searchable
      end

      def set_default_visibility
        self.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC if new_record?
      end

      property :additional_information, predicate: ::RDF::Vocab::DC.description do |index|
        index.as :stored_searchable
      end

      # multiple: false, until "conference" is converted to a nested attribute so that the location, name, and section are all related/stored together
      property :conference_location, predicate: ::RDF::URI.new("http://d-nb.info/standards/elementset/gnd#placeOfConferenceOrEvent"), multiple: false do |index|
        index.as :stored_searchable
      end

      # multiple: false, until "conference" is converted to a nested attribute so that the location, name, and section are all related/stored together
      property :conference_name, predicate: ::RDF::Vocab::BIBO.presentedAt, multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      # multiple: false, until "conference" is converted to a nested attribute so that the location, name, and section are all related/stored together
      property :conference_section, predicate: ::RDF::URI.new("https://w2id.org/scholarlydata/ontology/conference-ontology.owl#Track"), multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      # accessor attribute used only to group the date fields and allow proper ordering in the forms
      attr_accessor :dates_section

      property :date_accepted, predicate: ::RDF::Vocab::DC.dateAccepted, multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      property :date_collected, predicate: ::RDF::Vocab::DWC.measurementDeterminedDate do |index|
        index.as :stored_searchable, :facetable
      end

      property :date_reviewed, predicate: ::RDF::URI.new("http://schema.org/lastReviewed") do |index|
        index.as :stored_searchable
      end

      property :date_valid, predicate: ::RDF::Vocab::DC.valid, multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      property :degree_field, predicate: ::RDF::URI.new("http://vivoweb.org/ontology/core#majorField") do |index|
        index.as :stored_searchable, :facetable
      end

      # accessor value used by AddOtherFieldOptionActor to persist "Other" values provided by the user
      attr_accessor :degree_field_other

      property :degree_level, predicate: ::RDF::URI.new("http://purl.org/NET/UNTL/vocabularies/degree-information/#level"), multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      # accessor value used by AddOtherFieldOptionActor to persist "Other" values provided by the user
      attr_accessor :degree_level_other

      # 67 description.thesisdegreename
      property :degree_name, predicate: ::RDF::URI.new("http://purl.org/ontology/bibo/ThesisDegree") do |index|
        index.as :stored_searchable, :facetable
      end

      # accessor value used by AddOtherFieldOptionActor to persist "Other" values provided by the user
      attr_accessor :degree_name_other

      property :digitization_spec, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/conversionSpecifications") do |index|
        index.as :stored_searchable
      end

      # property :doi, predicate: ::RDF::Vocab::Identifiers.doi, multiple: false do |index|
      #  index.as :stored_searchable, :facetable
      # end

      property :dspace_collection, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/dspaceCollection") do |index|
        index.as :stored_searchable
      end

      property :dspace_community, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/dspaceCommunity") do |index|
        index.as :stored_searchable
      end

      property :file_extent, predicate: ::RDF::Vocab::DC.extent do |index|
        index.as :stored_searchable
      end

      property :funding_body, predicate: ::RDF::Vocab::MARCRelators.fnd do |index|
        index.as :stored_searchable, :facetable
      end

      property :funding_statement, predicate: ::RDF::URI.new("http://datacite.org/schema/kernel-4/fundingReference") do |index|
        index.as :stored_searchable, :facetable
      end

      property :hydrologic_unit_code, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/hydrologicUnitCode") do |index|
        index.as :stored_searchable, :facetable
      end

      property :import_url, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#importUrl'), multiple: false do |index|
        index.as :stored_searchable
      end

      property :in_series, predicate: ::RDF::URI.new("http://lsdis.cs.uga.edu/projects/semdis/opus#in_series") do |index|
        index.as :stored_searchable
      end

      property :keyword, predicate: ::RDF::Vocab::DC11.subject do |index|
        index.as :stored_searchable
      end

      property :label, predicate: ActiveFedora::RDF::Fcrepo::Model.downloadFilename, multiple: false do |index|
        index.as :stored_searchable
      end

      property :license, predicate: ::RDF::Vocab::DC.rights do |index|
        index.as :stored_searchable, :facetable
      end

      # property :nested_geo, :predicate => ::RDF::URI("https://purl.org/geojson/vocab#Feature"), :class_name => NestedGeo

      # property :nested_related_items, predicate: ::RDF::Vocab::DC.relation, :class_name => NestedRelatedItems do |index|
      #  index.as :stored_searchable
      # end

      # accessor value used by AddOtherFieldOptionActor to persist "Other" values provided by the user
      attr_accessor :other_affiliation_other

      property :prior_identifier, predicate: ActiveFedora::RDF::Fcrepo::Model.altIds, multiple: true do |index|
        index.as :stored_searchable
      end

      property :related_url, predicate: ::RDF::RDFS.seeAlso do |index|
        index.as :stored_searchable
      end

      property :relative_path, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#relativePath'), multiple: false do |index|
        index.as :stored_searchable
      end

      property :replaces, predicate: ::RDF::Vocab::DC.replaces, multiple: false do |index|
        index.as :stored_searchable
      end

      property :resource_type, predicate: ::RDF::Vocab::DC.type do |index|
        index.as :stored_searchable, :facetable
      end

      property :rights_statement, predicate: ::RDF::Vocab::EDM.rights do |index|
        index.as :stored_searchable, :facetable
      end

      property :source, predicate: ::RDF::Vocab::DC.source do |index|
        index.as :stored_searchable
      end

      # START These are ALL the metadata from Dspace

      # 1  contributor  author
      property :contributor_author, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/contributorAuthor") do |index|
        index.as :stored_searchable
      end

      # 2  contributor  advisor
      property :contributor_advisor, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/contributorAdvisor") do |index|
        index.as :stored_searchable
      end

      # 3  contributor - part of basic metadata
      property :contributor, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/contributorMain") do |index|
        index.as :stored_searchable
      end

      # 4  contributor  editor
      property :contributor_editor, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/contributorEditor") do |index|
        index.as :stored_searchable
      end

      # 5  contributor  illustrator
      property :contributor_illustrator, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/contributorIllustrator") do |index|
        index.as :stored_searchable
      end

      # 6  contributor
      property :contributor, predicate: ::RDF::Vocab::DC11.contributor do |index|
        index.as :stored_searchable
      end

      # 7  coverage     spatial - part of basic metadata
      property :based_near, predicate: ::RDF::Vocab::DC.spatial, class_name: Hyrax::ControlledVocabularies::Location do |index|
        index.as :stored_searchable, :facetable
      end

      # 8  coverage     temporal
      property :coverage_temporal, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/coverageTemporal") do |index|
        index.as :stored_searchable
      end

      # 9 creator null - part of basic
      property :creator, predicate: ::RDF::Vocab::DC11.creator do |index|
        index.as :stored_searchable, :facetable
      end

      #  10  date
      property :date, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/date") do |index|
        index.as :stored_searchable
      end

      # 11  date         accessioned
      property :date_accessioned, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/dateAccessioned") do |index|
        index.as :stored_searchable
      end

      # 12  date         available
      property :date_available, predicate: ::RDF::Vocab::DC.available, multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      # 13 date          copyright
      property :date_copyright, predicate: ::RDF::Vocab::DC.dateCopyrighted, multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      #  14  date         created - part of basic metadata
      property :date_created, predicate: ::RDF::Vocab::DC.created, multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      #  15  date         issued
      property :date_issued, predicate: ::RDF::Vocab::DC.issued, multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      #  16  date         submitted
      property :date_submitted, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/dateSubmitted") do |index|
        index.as :stored_searchable
      end

      # 17  identifier - part of basic metadata
      property :identifier, predicate: ::RDF::Vocab::DC.identifier do |index|
        index.as :stored_searchable
      end

      #  18  identifier   citation - part of basic metadata
      property :bibliographic_citation, predicate: ::RDF::Vocab::DC.bibliographicCitation

      #  19  identifier   govdoc
      property :identifier_govdoc, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierGovdoc") do |index|
        index.as :stored_searchable
      end

      #  20  identifier   isbn
      property :isbn, predicate: ::RDF::Vocab::Identifiers.isbn do |index|
        index.as :stored_searchable
      end

      # 21  identifier   issn
      property :issn, predicate: ::RDF::Vocab::Identifiers.issn do |index|
        index.as :stored_searchable
      end

      # 22  identifier   sici
      property :identifier_sici, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierSici") do |index|
        index.as :stored_searchable
      end

      # 23  identifier   ismn
      property :identifier_ismn, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierIsmn") do |index|
        index.as :stored_searchable
      end

      # 24  identifier   other
      property :identifier_other, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierOther") do |index|
        index.as :stored_searchable
      end

      #  25  identifier   uri
      property :identifier_uri, predicate: ::RDF::Vocab::Identifiers.uri do |index|
        index.as :stored_searchable
      end

      # 26  description
      property :desciption_none, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionNone") do |index|
        index.as :stored_searchable
      end

      # 26 description null - part of basic metadata
      property :description, predicate: ::RDF::Vocab::DC11.description do |index|
        index.as :stored_searchable
      end

      # 27  description  abstract
      property :description_abstract, predicate: ::RDF::Vocab::DC.abstract do |index|
        index.as :stored_searchable
      end

      # 28  description  provenance
      property :description_provenance, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionProvenance") do |index|
        index.as :stored_searchable
      end

      # 29  description  sponsorship
      property :description_sponsorship, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionSponsorship") do |index|
        index.as :stored_searchable
      end

      # 30  description  statementofresponsibility
      property :description_statementofresponsibility, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionStatementofresponsibility") do |index|
        index.as :stored_searchable
      end

      # 31  description  tableofcontents
      property :tableofcontents, predicate: ::RDF::Vocab::DC.tableOfContents do |index|
        index.as :stored_searchable
      end

      #  32  description  uri
      property :description_uri, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionUri") do |index|
        index.as :stored_searchable
      end

      # 33  format
      property :file_format, predicate: ::RDF::Vocab::DC.FileFormat do |index|
        index.as :stored_searchable, :facetable
      end

      # 34  format       extent
      property :format_extent, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/formatExtent") do |index|
        index.as :stored_searchable
      end

      # 35  format       medium
      property :format_medium, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/formatMedium") do |index|
        index.as :stored_searchable
      end

      # 36  format       mimetype
      property :format_mimetype, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/formatMimetype") do |index|
        index.as :stored_searchable
      end

      # 37  language   - not needed
      property :language_none, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/languageNone") do |index|
        index.as :stored_searchable
      end

      # 38  language     iso - part of basic metadata
      property :language, predicate: ::RDF::Vocab::DC11.language do |index|
        index.as :stored_searchable, :facetable
      end

      # 39  publisher  - part of basic metadata
      property :publisher, predicate: ::RDF::Vocab::DC11.publisher do |index|
        index.as :stored_searchable
      end

      # 40  relation
      property :relation_none, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationNone") do |index|
        index.as :stored_searchable
      end

      # 41  relation     isformatof
      property :relation_isformatof, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationIsformatof") do |index|
        index.as :stored_searchable
      end

      # 42  relation     ispartof
      property :part_of, predicate: ::RDF::Vocab::DC.isPartOf do |index|
        index.as :stored_searchable
      end

      # 43  relation     ispartofseries
      property :relation_ispartofseries, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationIspartofseries") do |index|
        index.as :stored_searchable
      end

      # 44  relation     haspart
      property :relation_haspart, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationHaspart") do |index|
        index.as :stored_searchable
      end

      # 45  relation     isversionof
      property :relation_isversionof, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationIsversionof") do |index|
        index.as :stored_searchable
      end

      # 46  relation     hasversion
      property :relation_hasversion, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationHasversion") do |index|
        index.as :stored_searchable
      end

      # 47  relation     isbasedon
      property :relation_isbaseson, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationIsbasedon") do |index|
        index.as :stored_searchable
      end

      # 48  relation     isreferencedby
      property :relation_isreferenceby, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationIsreferebcedby") do |index|
        index.as :stored_searchable
      end

      # 49  relation     requires
      property :relation_require, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationRequires") do |index|
        index.as :stored_searchable
      end

      # 50  relation     replaces
      property :relation_replaces, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationReplaces") do |index|
        index.as :stored_searchable
      end

      # 51  relation     isreplacedby
      property :relation_isrplacedby, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationIsreplacedby") do |index|
        index.as :stored_searchable
      end

      # 52  relation     uri
      property :relation_uri, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/relationUri") do |index|
        index.as :stored_searchable
      end

      # 53  rights
      property :rights_None, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/rightsNone") do |index|
        index.as :stored_searchable
      end

      # 54  rights       uri
      property :rights_uri, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/rightsUri") do |index|
        index.as :stored_searchable
      end

      # 55  source - part of basic metadata
      property :source, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/sourceNone") do |index|
        index.as :stored_searchable
      end

      # 56  source       uri
      property :source_uri, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/sourceUri") do |index|
        index.as :stored_searchable
      end

      # 57 subject - part of basic metadata
      property :subject, predicate: ::RDF::Vocab::DC.subject do |index|
        index.as :stored_searchable, :facetable
      end

      #  58  subject      classification
      property :source_classification, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/sourceClassification") do |index|
        index.as :stored_searchable
      end

      #  59  subject      ddc
      property :subject_ddc, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/subjectDdc") do |index|
        index.as :stored_searchable
      end

      # 60  subject      lcc
      property :subject_lcc, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/subjectLcc") do |index|
        index.as :stored_searchable
      end

      # 61  subject      lcsh
      property :subject_lcsh, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/subjectLcsh") do |index|
        index.as :stored_searchable
      end

      # 62  subject      mesh
      property :subject_mesh, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/subjectMesh") do |index|
        index.as :stored_searchable
      end

      # 63  subject      other
      property :subject_other, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/subjectOther") do |index|
        index.as :stored_searchable
      end

      # 64  title   - part of basic metadata
      property :title, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/titleNone") do |index|
        index.as :stored_searchable
      end

      # 65  title        alternative
      property :alt_title, predicate: ::RDF::Vocab::DC.alternative do |index|
        index.as :stored_searchable
      end

      # 66  type
      property :type_none, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/typeNone") do |index|
        index.as :stored_searchable
      end

      property :type_snre, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/typeSnre") do |index|
        index.as :stored_searchable
      end

      # 67  description  thesisdegreename
      property :description_thesisdegreename, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionThesisdegreename") do |index|
        index.as :stored_searchable
      end

      # 68  description  thesisdegreediscipline
      property :description_thesisdegreediscipline, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionThesisdegreediscipline") do |index|
        index.as :stored_searchable
      end

      # 69  description  thesisdegreegrantor
      property :description_thesisdegreegrantor, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionThesisdegreegrantor") do |index|
        index.as :stored_searchable
      end

      # 70  contributor  committeemember
      property :contributor_committeemember, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/contributorCommitteemember") do |index|
        index.as :stored_searchable
      end

      # 71  rights       robots
      property :rights_robots, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/rightsRobots") do |index|
        index.as :stored_searchable
      end

      # 72  subject      hlbsecondlevel
      property :subject_hlbsecondlevel, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/subjectHlbsecondlevel") do |index|
        index.as :stored_searchable
      end

      # 73  subject      hlbtoplevel
      property :subject_hlbtoplevel, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/subjectHlbtoplevel") do |index|
        index.as :stored_searchable
      end

      # 74  description  peerreviewed
      property :peerreviewed, predicate: ::RDF::URI("http://purl.org/ontology/bibo/peerReviewed"), multiple: false do |index|
        index.as :stored_searchable, :facetable
      end

      # 75  contributor  affiliationum
      property :academic_affiliation, predicate: ::RDF::URI("http://vivoweb.org/ontology/core#AcademicDepartment") do |index|
        index.as :stored_searchable, :facetable
      end

      #  76  contributor  affiliationother
      property :other_affiliation, predicate: ::RDF::URI("http://vivoweb.org/ontology/core#Department") do |index|
        index.as :stored_searchable, :facetable
      end

      # 77  contributor  affiliationumcampus
      property :contributor_affiliationumcampus, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/contributorAffiliationumcampus") do |index|
        index.as :stored_searchable
      end

      # 78  identifier   uniqname
      property :identifier_uniqname, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierUniqname") do |index|
        index.as :stored_searchable
      end

      # 79  identifier   videostream
      property :identifier_videostream, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierVideostream") do |index|
        index.as :stored_searchable
      end

      # 80  identifier   pmid
      property :identifier_pmid, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierPmid") do |index|
        index.as :stored_searchable
      end

      # 81  identifier   oclc
      property :identifier_oclc, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierOclc") do |index|
        index.as :stored_searchable
      end

      # 82  description  withdrawalreason
      property :embargo_reason, predicate: ::RDF::Vocab::DC.accessRights, multiple: false do |index|
        index.as :stored_searchable
      end

      # 83  description  bitstreamurl
      property :description_bitstreamurl, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionBitstreamurl") do |index|
        index.as :stored_searchable
      end

      # 84  identifier   doi
      property :identifier_doi, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierDoi") do |index|
        index.as :stored_searchable
      end

      # 85  identifier   source
      property :identifier_source, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierSource") do |index|
        index.as :stored_searchable
      end

      # 86  identifier   citedreference
      property :identifier_citedreference, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierCitedreference") do |index|
        index.as :stored_searchable
      end

      # 87  contributor  authoremail
      property :contributor_authoremail, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/contributorAuthoremail") do |index|
        index.as :stored_searchable
      end

      # 88  requestcopy  email
      property :requestcopy_email, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/requestcopyEmail") do |index|
        index.as :stored_searchable
      end

      # 89  requestcopy  name
      property :requestcopy_name, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/requestcopyName") do |index|
        index.as :stored_searchable
      end

      # 90  identifier   imageclass
      property :identifier_imageclass, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierImageclass") do |index|
        index.as :stored_searchable
      end

      # 91  description  mapping
      property :description_mapping, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionMapping") do |index|
        index.as :stored_searchable
      end

      # 92  language     rfc3066

      # 93  description  version
      property :description_version, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionVersion") do |index|
        index.as :stored_searchable
      end


      # 94  rights       holder
      property :rights_holder, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/rightsHolder") do |index|
        index.as :stored_searchable
      end

      # 95  date         updated
      property :date_updated, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/dateUpdated") do |index|
        index.as :stored_searchable
      end

      # 96  description  md5checksum
      property :description_md5checksum, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionMd5checksum") do |index|
        index.as :stored_searchable
      end

      # 97  rights       access
      property :rights_access, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/rightsAccess") do |index|
        index.as :stored_searchable
      end

      # 99  description  hathi
      property :description_hathi, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionHathi") do |index|
        index.as :stored_searchable
      end

      # 100  description  restriction
      property :description_restriction, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionRestriction") do |index|
        index.as :stored_searchable
      end

      # 101  identifier   orcid
      property :identifier_orcid, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierOrcid") do |index|
        index.as :stored_searchable
      end

      # 102  description  filedescription
      property :description_filedescription, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionFiledescription") do |index|
        index.as :stored_searchable
      end

      # 103  date         open
      property :date_open, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/dateOpen") do |index|
        index.as :stored_searchable
      end

      # 104  rights       copyright
      property :rights_copyright, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/rightsCopyright") do |index|
        index.as :stored_searchable
      end

      # 105  provenance
      property :provenance_none, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/provenanceNone") do |index|
        index.as :stored_searchable
      end

      # 106  rights       license
      property :rights_license, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/rightsLicense"), multiple: false do |index|
        index.as :stored_searchable
      end

      property :rights_license_other, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/rightsLicenseOther"), multiple: false do |index|
        index.as :stored_searchable
      end

      # 166  identifier   slug
      property :identifier_slug, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/identifierSlug") do |index|
        index.as :stored_searchable
      end

      # 167  description  depositor - part of basic metadata :depositor
      # property :depositor, predicate: ::RDF::URI.new("http://opaquenamespace.org/ns/descriptionDepositor") do |index|
      #  index.as :stored_searchable
      # end

      # END These are ALL the metadata from Dspace

      # accessor attribute used only to group the nested_geo fields and allow proper ordering in the forms
      attr_accessor :geo_section

      # accessor attribute used only to allow validators to check selected options depending on current_user role
      attr_accessor :current_username

      class_attribute :controlled_properties
      self.controlled_properties = [:based_near]

      accepts_nested_attributes_for :based_near, allow_destroy: true, reject_if: proc { |a| a[:id].blank? }
      # accepts_nested_attributes_for :nested_geo, :allow_destroy => true, :reject_if => :all_blank
      # accepts_nested_attributes_for :nested_related_items, :allow_destroy => true, :reject_if => :all_blank

    end
  end

end
