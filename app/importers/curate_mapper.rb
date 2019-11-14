# frozen_string_literal: true

class CurateMapper < Zizia::HashMapper
  attr_reader :row_number

  CURATE_TERMS_MAP = {
      access_deepblue: "access_deepblue",
      admin_set_id: "admin_set_id",
      authoremail: "authoremail",
      creator: "creator",
      curation_notes_admin: "curation_notes_admin",
      curation_notes_user: "curation_notes_user",
      date_coverage: "date_coverage",
      date_created: "date_created",
      date_modified: "date_modified",
      date_published: "date_published",
      date_updated: "date_updated",
      depositor: "depositor",
      description: "description",
      doi: "doi",
      file_set_ids: "file_set_ids",
      fundedby: "fundedby",
      fundedby_other: "fundedby_other",
      grantnumber: "grantnumber",
      keyword: "keyword",
      language: "language",
      location: "location",
      methodology: "methodology",
      prior_identifier: "prior_identifier",
      referenced_by: "referenced_by",
      rights_license: "rights_license",
      rights_license_other: "rights_license_other",
      subject_discipline: "subject_discipline",
      title: "title",
      tombstone: "tombstone",
      total_file_count: "total_file_count",
      total_file_size: "total_file_size",
      total_file_size_human_readable: "total_file_size_human_readable",
      visibility: "visibility"
  }.freeze

  DELIMITER = '|'

  def initialize(attributes = {})
    @row_number = attributes[:row_number]
    super()
  end

  # What columns are allowed in the CSV
  def self.allowed_headers
    CURATE_TERMS_MAP.values + ['filename', 'type', 'intermediate_file', 'fileset_label', 'preservation_master_file']
  end

  # Given a field name, return the CSV header
  def self.csv_header(field)
    CURATE_TERMS_MAP[field.to_sym]
  end

  def fields
    # The fields common to all object types
    common_fields = CURATE_TERMS_MAP.keys
    common_fields
  end

  # Zizia expects files to return an Array
  def files
    [@metadata["Filename"]]
  end

  # Samvera generally assumes that all fields are multi-valued. Curate, however,
  # has many fields that are defined to be singular. This method returns the array
  # of single-value fields for an easy way to check whether a field is single-valued
  # or multi-valued when mapping it.
  def singular_fields
    work = DataSet.new
    properties = work.send(:properties)
    properties.select { |_k, v| v.respond_to? :multiple? }.select { |_k, v| !v.multiple? }.keys
  end

  # Match a visibility string to the value below; default to restricted
  def visibility
    value_from_csv = metadata['visibility']&.squish&.downcase
    visibility_mapping.fetch(value_from_csv, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
  end

  # The visibility values have different values when
  # they are calculated or indexed in solr than the
  # values that appear in the UI edit form.  We should
  # accept both.
  def visibility_mapping
    {
      'private' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
      'restricted' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
      'authenticated' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'registered' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'emory' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'emory network' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      'open' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      'public' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      'public low view' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
      'emory low download' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
      'rose high view' => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
    }.freeze
  end

  # Return the title if there is one. Otherwise, set it to a placeholder value.
  # We will sometimes have CSV rows that contain only a Filename, but no metadata.
  def title
    value = @metadata["title"] || "Unknown Title"
    Array.wrap(value)
  end

  # Normalize the value coming in because there are subtle mis-matches against the expected controlled
  # vocabulary term. E.g.,
  # "Stuart A. Rose Manuscript, Archives and Rare Book Library" vs
  # "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
  def administrative_unit
    csv_term = @metadata["administrative_unit"]
    return nil unless csv_term
    normalized_csv_term = csv_term.downcase.gsub(/[^a-z0-9\s]/i, '')
    active_terms = Qa::Authorities::Local.subauthority_for('administrative_unit').all.select { |term| term[:active] }
    valid_option = active_terms.select { |s| s["id"].downcase.gsub(/[^a-z0-9\s]/i, '') == normalized_csv_term }.try(:first)
    return valid_option["id"] if valid_option
    raise "Invalid administrative_unit value: #{csv_term}"
  end

  # Iterate through all values for data_classifications and ensure they are all
  # valid options according to Questioning Authority
  def data_classifications
    return nil unless @metadata["data_classifications"]
    csv_terms = @metadata["data_classifications"]&.split(DELIMITER)
    active_terms = Qa::Authorities::Local.subauthority_for('data_classifications').all.select { |term| term[:active] }
    data_classification_values = []
    csv_terms.each do |c|
      valid_option = active_terms.select { |s| s["id"] == c }.try(:first)
      raise "Invalid data_classification value: #{c}" unless valid_option
      data_classification_values << valid_option["id"]
    end
    data_classification_values
  end

  def rights_statement
    byebug
    return nil unless @metadata["rights_statement"]
    active_terms = Qa::Authorities::Local.subauthority_for('rights_statements').all.select { |term| term[:active] }
    csv_term = @metadata["rights_statement"]
    valid_uri_option = active_terms.select { |s| s["id"] == csv_term }.try(:first)
    return [csv_term] if valid_uri_option
    raise "Invalid rights_statement value: #{csv_term}"
  end

  def truthy?(term)
    return true if term.downcase.strip == "yes"
    return true if term.downcase.strip == "true"
    false
  end

  def falsey?(term)
    return true if term.downcase.strip == "no"
    return true if term.downcase.strip == "false"
    false
  end

  def sensitive_material
    csv_term = @metadata["sensitive_material"]
    return nil unless csv_term
    active_terms = Qa::Authorities::Local.subauthority_for('sensitive_material').all.select { |term| term[:active] }
    transformed_term = false if falsey?(csv_term)
    transformed_term = true if truthy?(csv_term)
    valid_option = active_terms.select { |s| s["id"] == transformed_term }.try(:first)
    return transformed_term.to_s if valid_option
    raise "Invalid sensitive_material value: #{csv_term}"
  end

  def content_genres
    Array.wrap(@metadata['content_genres'])
  end

  # If we get a URI for content_type, check that it matches a URI in the questioning
  # authority config, and return it if so.
  # If we get a string for contenttype, (e.g., 'still image'), transform it into its
  # corresponding Questioning Authority controlled vocabulary uri.
  def content_type
    csv_term = @metadata["content_type"]
    return unless csv_term
    active_terms = Qa::Authorities::Local.subauthority_for('resource_types').all.select { |term| term[:active] }

    # Check whether this is a uri that matches a valid URI option
    valid_uri_option = active_terms.select { |s| s["id"] == csv_term }.try(:first)
    return valid_uri_option["id"] if valid_uri_option && valid_uri_option["id"]
    # Check whether this is a string that can be easily matched to a valid URI
    matching_term = active_terms.select { |s| s["label"].downcase.strip == csv_term.downcase.strip }.first
    raise "Invalid resource_type value: #{csv_term}" unless matching_term
    matching_term["id"]
  end

  def map_field(name)
    return unless CURATE_TERMS_MAP.keys.include?(name)
    return @metadata[name.to_s] if singular_fields.include?(name.to_s)

    Array.wrap(CURATE_TERMS_MAP[name]).map do |source_field|
      metadata[source_field]&.split(DELIMITER)
    end.flatten.compact
  end
end
