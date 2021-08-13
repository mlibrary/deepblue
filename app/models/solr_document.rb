# frozen_string_literal: true

class SolrDocument

  mattr_accessor :solr_document_debug_verbose,
                 default: ::DeepBlueDocs::Application.config.solr_document_debug_verbose

  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument

  # include BlacklightOaiProvider::SolrDocumentBehavior

  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior
  include Umrdr::SolrDocumentBehavior

  # .unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # This fails to load.
  # use_extension(::ScholarsArchive::Document::QualifiedDublinCore)

  # Do content negotiation for AF models.

  use_extension( Hydra::ContentNegotiation )

  def self.solrized_methods(property_names)
    property_names.each do |property_name|
      define_method property_name.to_sym do
        self[Solrizer.solr_name(property_name)]
      end
    end
  end

  def self.all_property_names
    @@all_property_names
  end

  def all_property_names
    @@all_property_names
  end

  # Oai - to have sets.
  def sets
    AdminsetSet.sets_for(self)
  end

  def model_property_names_browse
    model_name = self['has_model_ssim'].first
    ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                            "model_name=#{model_name}",
                                            "" ] ) if solr_document_debug_verbose
    rv = case model_name
         when 'Collection'
           Collection.metadata_keys_browse
         when 'DataSet'
           DataSet.metadata_keys_browse
         when 'FileSet'
           FileSet.metadata_keys_browse
         else
           []
         end
    ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                            "rv=#{rv}",
                                            "" ] ) if solr_document_debug_verbose
    return rv
  end

  def academic_affiliation_label
    # references to ScholarsArchive raise ActionView::Template::Error (uninitialized constant SolrDocument::ScholarsArchive)
    # ScholarsArchive::LabelParserService.parse_label_uris(self['academic_affiliation_label_ssim'])
    self['academic_affiliation_label_ssim']
  end

  def curation_notes_admin_label
    self['curation_notes_admin_label_ssim']
  end

  def curation_notes_user_label
    self['curation_notes_user_label_ssim']
  end

  def date_published_label
    self['date_published_dtsim']
  end

  def degree_field_label
    # references to ScholarsArchive raise ActionView::Template::Error (uninitialized constant SolrDocument::ScholarsArchive)
    # ScholarsArchive::LabelParserService.parse_label_uris(self['degree_field_label_ssim'])
    self['degree_field_label_ssim']
  end

  def degree_grantors_label
    # references to ScholarsArchive raise ActionView::Template::Error (uninitialized constant SolrDocument::ScholarsArchive)
    # ScholarsArchive::LabelParserService.parse_label_uris(self['degree_grantors_label_ssim'])
    self['degree_grantors_label_ssim']
  end

  def description_label
    self['description_ssim']
  end

  def description_file_set_label
    self['description_file_set_ssim']
  end

  def doi_label
    self['doi_label_ssim']
  end

  def access_deepblue_label
    self['access_deepblue_label_ssim']
  end

  def fundedby_label
    self['fundedby_label_ssim']
  end

  def fundedby_other_label
    self['fundedby_other_label_ssim']
  end

  def grantnumber_label
    self['grantnumber_label_ssim']
  end

  def referenced_by_label
    self['referenced_by_label_ssim']
  end

  def language_label
    self['language_label_ssim']
  end

  def license_label
    self['license_label_ssim']
  end

  def methodology_label
    self['methodology_label_ssim']
  end

  def nested_geo
    self[Solrizer.solr_name('nested_geo_label', :symbol)] || []
  end

  def nested_related_items_label
    # references to ScholarsArchive raise ActionView::Template::Error (uninitialized constant SolrDocument::ScholarsArchive)
    # ScholarsArchive::LabelParserService.parse_label_uris(self[Solrizer.solr_name('nested_related_items_label', :symbol)]) || []
    self[Solrizer.solr_name('nested_related_items_label', :symbol)] || []
  end

  def other_affiliation_label
    # references to ScholarsArchive raise ActionView::Template::Error (uninitialized constant SolrDocument::ScholarsArchive)
    # ScholarsArchive::LabelParserService.parse_label_uris(self['other_affiliation_label_ssim'])
    self['other_affiliation_label_ssim']
  end

  def peerreviewed_label
    self['peerreviewed_label_ssim']
  end

  def prior_identifier_label
    self['prior_identifier_label_ssim']
  end

  def read_me_file_set_id_label
    self['read_me_file_set_id_label_ssim']
  end

  def rights_license_label
    self['rights_license_label_ssim']
  end

  def rights_license_other_label
    self['rights_license_other_label_ssim']
  end

  def rights_statement_label
    self['rights_statement_label_ssim']
  end

  def subject_discipline_label
    self['subject_discipline_label_ssim']
  end

  def system_created
    Time.parse self['system_create_dtsi']
  end

  @@all_property_names = [
    'abstract',
    'academic_affiliation',
    'additional_information',
    'language_none',
    'peerreviewed',
    'alt_title',
    'bibliographic_citation',
    'conference_location',
    'conference_name',
    'conference_section',
    'contributor_advisor',
    'contributor_affiliationumcampus',
    'contributor_author',
    'contributor_committeemember',
    'curation_notes_admin',
    'curation_notes_user',
    'date_accepted',
    'date_available',
    'date_collected',
    'date_copyright',
    'date_issued',
    'date_published',
    'date_reviewed',
    'date_submitted',
    'date_valid',
    'degree_discipline',
    'degree_field',
    'degree_grantors',
    'degree_level',
    'degree_name',
    'description_abstract',
    'description_file_set',
    'description_mapping',
    'description_sponsorship',
    'description_thesisdegreediscipline',
    'description_thesisdegreegrantor',
    'description_thesisdegreename',
    'digitization_spec',
    'doi',
    'dspace_collection',
    'dspace_community',
    'duration',
    'editor',
    'embargo_reason',
    'file_extent',
    'file_format',
    'fundedby',
    'fundedby_other',
    'funding_body',
    'funding_statement',
    'graduation_year',
    'grantnumber',
    'has_journal',
    'has_number',
    'has_volume',
    'hydrologic_unit_code',
    'identifier',
    'identifier_orcid',
    'identifier_source',
    'identifier_uniqname',
    'in_series',
    'interactivity_type',
    'is_based_on_url',
    'isbn',
    'issn',
    'language',
    'learning_resource_type',
    'methodology',
    'other_affiliation',
    'prior_identifier',
    'read_me_file_set_id',
    'referenced_by',
    'relation_ispartofseries',
    'replaces',
    'rights_license',
    'rights_license_other',
    'subject_discipline',
    'subject_other',
    'tableofcontents',
    'time_required',
    'type_none',
    'typical_age_range',
    'virus_scan_service',
    'virus_scan_status',
    'virus_scan_status_date'
  ]

  solrized_methods @@all_property_names

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  field_semantics.merge!(
    contributor:  [ 'contributor_tesim',
                    'editor_tesim',
                    'contributor_advisor_tesim',
                    'contributor_committeemember_tesim',
                    'oai_academic_affiliation_label',
                    'oai_other_affiliation_label' ],
    coverage:     ['based_near_label_tesim', 'conferenceLocation_tesim'],
    creator:      'creator_tesim',
    date:         'date_created_tesim',
    description:  ['description_tesim', 'abstract_tesim'],
    format:       ['file_extent_tesim', 'file_format_tesim'],
    identifier:   'oai_identifier',
    language:     'language_label_tesim',
    publisher:    'publisher_tesim',
    relation:     'oai_nested_related_items_label',
    rights:       'oai_rights',
    source:       ['source_tesim', 'isBasedOnUrl_tesim'],
    subject:      ['subject_tesim', 'keyword_tesim'],
    title:        'title_tesim',
    type:         'resource_type_tesim',
    doi:          'doi_tesim'
  )


  # Override SolrDocument hash access for certain virtual fields
  def [](key)
    return send(key) if [ 'oai_academic_affiliation_label',
                          'oai_other_affiliation_label',
                          'oai_rights',
                          'oai_identifier',
                          'oai_nested_related_items_label' ].include?(key)
    super
  end

  def sets
    fetch('isPartOf', []).map { |m| BlacklightOaiProvider::Set.new("isPartOf_ssim:#{m}") }
  end

  def oai_nested_related_items_label
    related_items = []
    nested_related_items_label.each do |r|
      related_items << r["label"] + ': ' + r["uri"]
    end
    related_items
  end

  def oai_academic_affiliation_label
    labels = []
    return labels unless academic_affiliation_label
    academic_affiliation_label.each do |a|
      labels << a["label"]
    end
    labels
  end

  def oai_other_affiliation_label
    labels = []
    return labels unless other_affiliation_label
    other_affiliation_label.each do |o|
      labels << o["label"]
    end
    labels
  end

  # Only return License if present, otherwise Rights
  def oai_rights
    license_label ? license_label : rights_statement_label
  end

  def oai_identifier
    if self["has_model_ssim"].first.to_s == "Collection"
      Hyrax::Engine.routes.url_helpers.url_for( only_path: false,
                                                action: 'show',
                                                host: CatalogController.blacklight_config.oai[:provider][:repository_url],
                                                controller: 'hyrax/collections',
                                                id: id )
    else
      Rails.application.routes.url_helpers.url_for( only_path: false,
                                                    action: 'show',
                                                    host: CatalogController.blacklight_config.oai[:provider][:repository_url],
                                                    controller: 'hyrax/' + self["has_model_ssim"].first.to_s.underscore.pluralize,
                                                    id: id )
    end
  end

end
