# frozen_string_literal: true

class Collection < ActiveFedora::Base
  include ::Hyrax::CollectionBehavior

  # You can replace these metadata if they're not suitable
  # include Hyrax::BasicMetadata
  include Umrdr::UmrdrWorkBehavior
  include Umrdr::UmrdrWorkMetadata

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Deepblue::DefaultMetadata

  include ::Deepblue::MetadataBehavior
  include ::Deepblue::EmailBehavior
  include ::Deepblue::ProvenanceBehavior

  before_destroy :provenance_before_destroy_collection

  self.indexer = Hyrax::CollectionWithBasicMetadataIndexer

  def provenance_before_destroy_collection
    provenance_destroy( current_user: '' ) # , event_note: 'provenance_before_destroy_collection' )
  end

  def metadata_keys_all
    %i[
      creator
      curation_notes_admin
      curation_notes_user
      description
      keyword
      language
      referenced_by
      subject_discipline
      title
      visibility
    ]
  end

  def metadata_keys_brief
    %i[
      creator
      title
      visibility
    ]
  end

  def metadata_keys_update
    %i[
      creator
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
              when 'collection_type'
                value = collection_type.machine_id
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
              when 'collection_type'
                value = collection_type.machine_id
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
              when 'collection_type'
                value = collection_type.machine_id
                true
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
    member_objects
  end

  def metadata_report_keys
    return USE_BLANK_KEY_VALUES, metadata_keys_all
  end

  def metadata_report_label_override( metadata_key:, metadata_value: ) # rubocop:disable Lint/UnusedMethodArgument
    case metadata_key.to_s
    when 'collection_type'
      'Collection Type: '
    when 'total_file_count'
      'Total File Count: '
    when 'total_file_size_human_readable'
      'Total File Size: '
    end
  end

  def metadata_report_title_pre
    'Collection: '
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


end
