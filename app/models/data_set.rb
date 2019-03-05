# frozen_string_literal: true

class DataSet < ActiveFedora::Base

  include ::Hyrax::WorkBehavior

  self.indexer = DataSetIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []

  # self.human_readable_type = 'Data Set' # deprecated
  include Umrdr::UmrdrWorkBehavior
  include Umrdr::UmrdrWorkMetadata

  validates :authoremail, presence: { message: 'You must have author contact information.' }
  validates :creator, presence: { message: 'Your work must have a creator.' }
  validates :description, presence: { message: 'Your work must have a description.' }
  validates :methodology, presence: { message: 'Your work must have a description of the method for collecting the dataset.' }
  validates :rights_license, presence: { message: 'You must select a license for your work.' }
  validates :title, presence: { message: 'Your work must have a title.' }

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Deepblue::DefaultMetadata

  include ::Deepblue::MetadataBehavior
  include ::Deepblue::EmailBehavior
  include ::Deepblue::ProvenanceBehavior

  after_initialize :set_defaults

  before_destroy :provenance_before_destroy_data_set

  def provenance_before_destroy_data_set
    provenance_destroy( current_user: '' ) # , event_note: 'provenance_before_destroy_data_set' )
  end

  DOI_PENDING = 'doi_pending'

  def set_defaults
    return unless new_record?
    self.resource_type = ["Dataset"]
  end

  def metadata_keys_all
    %i[
      admin_set_id
      authoremail
      creator
      curation_notes_admin
      curation_notes_user
      date_coverage
      date_created
      date_modified
      date_updated
      depositor
      description
      doi
      file_set_ids
      fundedby
      fundedby_other
      grantnumber
      keyword
      language
      location
      methodology
      prior_identifier
      referenced_by
      rights_license
      rights_license_other
      subject_discipline
      title
      tombstone
      total_file_count
      total_file_size
      total_file_size_human_readable
      visibility
    ]
  end

  # Title
  # Creator
  # Contact information
  # Discipline
  # Record URL
  def metadata_keys_email_standard
    %i[
      title
      creator
      depositor
      authoremail
      description
      subject_discipline
      location
    ]
  end

  def metadata_keys_brief
    %i[
      authoremail
      title
      visibility
    ]
  end

  def metadata_keys_report
    %i[
      authoremail
      creator
      curation_notes_user
      date_coverage
      depositor
      description
      doi
      fundedby
      fundedby_other
      grantnumber
      keyword
      language
      methodology
      referenced_by
      rights_license
      rights_license_other
      subject_discipline
      title
      total_file_count
      total_file_size_human_readable
    ]
  end

  def metadata_keys_update
    %i[
      authoremail
      title
      visibility
    ]
  end

  def attributes_all_for_email
    metadata_keys_all
  end

  def attributes_all_for_provenance
    metadata_keys_all
  end

  def attributes_brief_for_email
    metadata_keys_brief
  end

  def attributes_brief_for_provenance
    metadata_keys_brief
  end

  def attributes_standard_for_email
    metadata_keys_email_standard
  end

  def attributes_update_for_email
    metadata_keys_update
  end

  def attributes_update_for_provenance
    metadata_keys_update
  end

  def for_email_route
    for_event_route
  end

  def for_event_route
    Rails.application.routes.url_helpers.hyrax_data_set_path( id: self.id ) # rubocop:disable Style/RedundantSelf
  end

  def for_provenance_route
    for_event_route
  end

  def map_email_attributes_override!( event:, # rubocop:disable Lint/UnusedMethodArgument
                                      attribute:,
                                      ignore_blank_key_values:,
                                      email_key_values: )
    value = nil
    handled = case attribute.to_s
              when 'file_set_ids'
                value = file_set_ids
                true
              when 'total_file_count'
                value = total_file_count
                true
              when 'total_file_size_human_readable'
                value = total_file_size_human_readable
                true
              when 'visibility'
                value = visibility
                true
              else
                false
              end
    return false unless handled
    if ignore_blank_key_values
      email_key_values[attribute] = value if value.present?
    else
      email_key_values[attribute] = value
    end
    return true
  end

  def map_provenance_attributes_override!( event:, # rubocop:disable Lint/UnusedMethodArgument
                                           attribute:,
                                           ignore_blank_key_values:,
                                           prov_key_values: )
    value = nil
    handled = case attribute.to_s
              when 'file_set_ids'
                value = file_set_ids
                true
              when 'total_file_count'
                value = total_file_count
                true
              when 'total_file_size_human_readable'
                value = total_file_size_human_readable
                true
              when 'visibility'
                value = visibility
                true
              else
                false
              end
    return false unless handled
    if ignore_blank_key_values
      prov_key_values[attribute] = value if value.present?
    else
      prov_key_values[attribute] = value
    end
    return true
  end

  def metadata_hash_override( key:, ignore_blank_values:, key_values: )
    value = nil
    handled = case key.to_s
              when 'file_set_ids'
                value = file_set_ids
                true
              when 'total_file_count'
                value = total_file_count
                true
              when 'total_file_size'
                value = total_file_size
                true
              when 'total_file_size_human_readable'
                value = total_file_size_human_readable
                true
              # when 'visibility'
              #   value = visibility
              #   true
              else
                false
              end
    return false unless handled
    if ignore_blank_values
      key_values[key] = value if value.present?
    else
      key_values[key] = value
    end
    return true
  end

  def metadata_report_contained_objects
    file_sets
  end

  def metadata_report_keys
    return IGNORE_BLANK_KEY_VALUES, metadata_keys_report
  end

  def metadata_report_label_override( metadata_key:, metadata_value: ) # rubocop:disable Lint/UnusedMethodArgument
    case metadata_key.to_s
    when 'file_set_ids'
      'File Set IDs: '
    when 'total_file_count'
      'Total File Count: '
    when 'total_file_size_human_readable'
      'Total File Size: '
    end
  end

  def metadata_report_title_pre
    'DataSet: '
  end

  # # Visibility helpers
  # def private?
  #   visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  # end
  #
  # def public?
  #   visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  # end

  #
  # Make it so work does not show up in search result for anyone, not even admins.
  #
  def entomb!( epitaph, current_user )
    return false if tombstone.present?
    depositor_at_tombstone = depositor
    visibility_at_tombstone = visibility
    self.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    self.depositor = depositor
    self.tombstone = [epitaph]

    file_sets.each do |file_set|
      # TODO: FileSet#entomb!
      file_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    save
    provenance_tombstone( current_user: current_user,
                          epitaph: epitaph,
                          depositor_at_tombstone: depositor_at_tombstone,
                          visibility_at_tombstone: visibility_at_tombstone )
    true
  end

  # begin metadata

  # the list of creators is ordered
  def creator
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: creator_ordered, values: values )
    return values
  end

  def creator=( values )
    self.creator_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: creator_ordered, values: values )
    super values
  end

  # the list of curation_note_admin is ordered
  def curation_note_admin
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: curation_note_admin_ordered, values: values )
    return values
  end

  def curation_note_admin=( values )
    self.curation_note_admin_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: curation_note_admin_ordered, values: values )
    super values
  end

  # the list of curation_note_user is ordered
  def curation_note_user
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: curation_note_user_ordered, values: values )
    return values
  end

  def curation_note_user=( values )
    self.curation_note_user_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: curation_note_user_ordered, values: values )
    super values
  end

  # the list of description is ordered
  def description
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: description_ordered, values: values )
    return values
  end

  def description=( values )
    self.description_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: description_ordered, values: values )
    super values
  end

  #
  # the list of keyword is ordered
  #
  def keyword
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: keyword_ordered, values: values )
    return values
  end

  def keyword=( values )
    self.keyword_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: keyword_ordered, values: values )
    super values
  end

  #
  # handle the list of language as ordered
  #
  def language
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: language_ordered, values: values )
    return values
  end

  def language=( values )
    self.language_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: language_ordered, values: values )
    super values
  end

  #
  # handle the list of referenced_by as ordered
  #
  def referenced_by
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: referenced_by_ordered, values: values )
    return values
  end

  def referenced_by=( values )
    self.referenced_by_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: referenced_by_ordered, values: values )
    super values
  end

  # the list of title is ordered
  def title
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: title_ordered, values: values )
    return values
  end

  def title=( values )
    self.title_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: title_ordered, values: values )
    super values
  end

  # end metadata

  def total_file_count
    return 0 if file_set_ids.blank?
    file_set_ids.size
  end

end
