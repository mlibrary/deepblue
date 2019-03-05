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
      child_collection_ids
      child_collection_count
      child_work_ids
      child_work_count
      collection_type
      creator
      curation_notes_admin
      curation_notes_user
      date_created
      date_modified
      date_updated
      description
      keyword
      language
      prior_identifier
      referenced_by
      subject_discipline
      title
      total_file_size
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

  def metadata_keys_report
    %i[
      child_collection_count
      child_work_count
      collection_type
      creator
      curation_notes_user
      description
      keyword
      language
      referenced_by
      subject_discipline
      title
      total_file_size
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

  def attributes_standard_for_email
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

  def child_collection_count
    ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Collection").count
  end

  def child_collection_ids
    ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Collection").map { |w| w.id } # rubocop:disable Style/SymbolProc
  end

  def child_work_count
    ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Work").count
  end

  def child_work_ids
    ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Work").map { |w| w.id } # rubocop:disable Style/SymbolProc
  end

  def total_file_size
    bytes
  end

  def total_file_size_human_readable
    value = total_file_size
    ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
  end

  def map_email_attributes_override!( event:, # rubocop:disable Lint/UnusedMethodArgument
                                      attribute:,
                                      ignore_blank_key_values:,
                                      email_key_values: )
    value = nil
    handled = case attribute.to_s
              when 'child_collection_count'
                value = child_work_count
                true
              when 'child_collection_ids'
                value = collection_ids
              when 'child_work_count'
                value = child_work_count
                true
              when 'child_work_ids'
                value = child_work_ids
                true
              when 'collection_type'
                value = collection_type.machine_id
                true
              when 'total_file_size'
                value = total_file_size
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
              when 'child_collection_count'
                value = child_work_count
                true
              when 'child_collection_ids'
                value = collection_ids
              when 'child_work_count'
                value = child_work_count
                true
              when 'child_work_ids'
                value = child_work_ids
                true
              when 'collection_type'
                value = collection_type.machine_id
                true
              when 'total_file_size'
                value = total_file_size
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
              when 'child_collection_count'
                value = child_work_count
                true
              when 'child_collection_ids'
                value = collection_ids
              when 'child_work_count'
                value = child_work_count
                true
              when 'child_work_ids'
                value = child_work_ids
                true
              when 'collection_type'
                value = collection_type.machine_id
                true
              when 'total_file_size'
                value = total_file_size
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
    return IGNORE_BLANK_KEY_VALUES, metadata_keys_report
  end

  def metadata_report_label_override( metadata_key:, metadata_value: ) # rubocop:disable Lint/UnusedMethodArgument
    case metadata_key.to_s
    when 'child_collection_count'
      'Child Collection Count: '
    when 'child_collection_ids'
      'Child Collection Identifiers: '
    when 'child_work_count'
      'Child Work Count: '
    when 'child_work_ids'
      'Child Work Identifiers: '
    when 'collection_type'
      'Collection Type: '
    when 'total_file_size'
      'Total File Size: '
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
