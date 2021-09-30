# frozen_string_literal: true

class FileSet < ActiveFedora::Base

  mattr_accessor :file_set_debug_verbose, default: Rails.configuration.file_set_debug_verbose

  include ::Deepblue::FileSetMetadata # must be before `include ::Hyrax::FileSetBehavior`
  include ::Hyrax::FileSetBehavior
  include ::Deepblue::FileSetBehavior
  include ::Deepblue::MetadataBehavior
  include ::Deepblue::ProvenanceBehavior
  include ::Deepblue::DoiBehavior

  before_destroy :provenance_before_destroy_file_set

  def provenance_before_destroy_file_set
    # workflow_destroy does this
    # provenance_destroy( current_user: '' ) # , event_note: 'provenance_before_destroy_file_set' )
  end

  def metadata_keys_all
    %i[
      curation_notes_admin
      curation_notes_user
      date_created
      date_modified
      date_uploaded
      description_file_set
      doi
      file_extension
      files_count
      file_size
      file_size_human_readable
      label
      location
      mime_type
      original_checksum
      original_name
      parent_id
      prior_identifier
      title
      uri
      version_count
      virus_scan_service
      virus_scan_status
      virus_scan_status_date
      visibility
    ]
  end

  def self.metadata_keys_all
    @@metadata_keys_all ||= %i[
      curation_notes_admin
      curation_notes_user
      date_created
      date_modified
      date_uploaded
      description_file_set
      doi
      file_extension
      files_count
      file_size
      file_size_human_readable
      label
      location
      mime_type
      original_checksum
      original_name
      parent_id
      prior_identifier
      title
      uri
      version_count
      virus_scan_service
      virus_scan_status
      virus_scan_status_date
      visibility
    ].freeze
  end

  def metadata_keys_browse
    self.metadata_keys_browse
  end

  def self.metadata_keys_browse
    @@metadata_keys_browse ||= %i[
      date_created
      date_modified
      file_extension
      files_count
      file_size
      file_size_human_readable
      label
      location
      title
    ].freeze
  end

  def metadata_keys_brief
    %i[
      title
      label
      parent_id
      file_extension
      visibility
    ]
  end

  def self.metadata_keys_json
    @@metadata_keys_json ||= %i[
      id
      creator
      curation_notes_user
      date_modified
      date_uploaded
      depositor
      description
      doi
      file_size
      file_size_human_readable
      label
      mime_type
      title
      original_checksum
      virus_scan_service
      virus_scan_status
      virus_scan_status_date
    ].freeze
  end

  def metadata_keys_report
    %i[
      curation_notes_user
      description_file_set
      doi
      file_extension
      files_count
      file_size_human_readable
      label
      mime_type
      original_checksum
      original_name
      parent_id
      title
    ]
  end

  def metadata_keys_update
    %i[
      title
      label
      description_file_set
      parent_id
      file_extension
      version_count
      visibility
    ]
  end

  def metadata_keys_virus
    %i[
      title
      label
      parent_id
      file_extension
      virus_scan_service
      virus_scan_status
      virus_scan_status_date
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

  def attributes_virus_for_provenance
    metadata_keys_virus
  end

  def files_to_file
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "files=#{files}",
                                           "" ] if file_set_debug_verbose
    # caller_locations(0..5).each { |cl| puts cl }
    # caller_locations(0..25).each { |cl| puts cl }
    return nil if files.blank?
    # puts "label=#{label}"
    files.each do |f|
      # puts "f=#{f}"
      # # puts "f.file_name.class=#{f.file_name.class}"
      # # puts "Array(f.file_name)=#{Array(f.file_name)}"
      # # puts "f.file_name.to_a=#{f.file_name.to_a}"
      # # #puts "f.file_name.get_values=#{f.file_name.get_values}"
      # # #puts "f.file_name.methods.sort=#{f.file_name.methods.sort}"
      # puts "f.original_name=#{f.original_name}"
      # # puts "f.original_name.class=#{f.original_name.class}"
      return f if f.original_name.present?
    end
    nil
  end

  def for_provenance_route
    Rails.application.routes.url_helpers.hyrax_file_set_path( id: id )
  rescue ActionController::UrlGenerationError => e
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    return ''
  end

  def for_event_route
    Rails.application.routes.url_helpers.hyrax_file_set_path( id: self.id ) # rubocop:disable Style/RedundantSelf
  rescue ActionController::UrlGenerationError => e
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    return ''
  end

  def title_type
    human_readable_type
  end

  def map_provenance_attributes_override!( event:, # rubocop:disable Lint/UnusedMethodArgument
                                           attribute:,
                                           ignore_blank_key_values:,
                                           prov_key_values: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "event=#{event}",
                                           "attribute=#{attribute}",
                                           "ignore_blank_key_values=#{ignore_blank_key_values}",
                                           "prov_key_values=#{prov_key_values}",
                                           "" ] if file_set_debug_verbose
    value = nil
    handled = case attribute.to_s
              when 'file_extension'
                value = File.extname label if label.present?
                true
              when 'files_count'
                value = files.size
                true
              when 'file_size'
                value = file_size_value
                true
              when 'file_size_human_readable'
                value = file_size_value
                value = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
                true
              when 'label'
                value = label
                true
              when 'mime_type'
                value = mime_type
                true
              when 'parent_id'
                value = parent.id unless parent.nil?
                true
              when 'original_checksum'
                value = original_checksum.blank? ? '' : original_checksum[0]
                true
              when 'original_name'
                value = original_name_value
                true
              when 'uri'
                value = uri.value
                true
              when 'version_count'
                value = version_count
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

  def file_size_value
    if file_size.blank?
      original_file.nil? ? 0 : original_file.size
    else
      file_size[0]
    end
  end

  def original_name_value
    return '' if original_file.nil?
    return original_file.original_name if original_file.respond_to?( :original_name )
    return ''
  end

  def metadata_hash_override( key:, ignore_blank_values:, key_values: )
    value = nil
    handled = case key.to_s
              when 'file_extension'
                value = File.extname label if label.present?
                true
              when 'files_count'
                value = files.size
                true
              when 'file_size'
                value = file_size_value
                true
              when 'file_size_human_readable'
                value = file_size_value
                value = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
                true
              when 'label'
                value = label
                true
              when 'mime_type'
                value = mime_type
                true
              when 'parent_id'
                value = parent.id unless parent.nil?
                true
              when 'original_checksum'
                value = original_checksum.blank? ? '' : original_checksum[0]
                true
              when 'original_name'
                value = original_name_value
                true
              when 'uri'
                value = uri.value
                true
              when 'version_count'
                value = version_count
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

  def metadata_report_keys
    return IGNORE_BLANK_KEY_VALUES, metadata_keys_report
  end

  def metadata_report_title_pre
    'FileSet: '
  end

  # begin metadata

  # the list of curation_notes_admin is ordered
  def curation_notes_admin
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: curation_notes_admin_ordered, values: values )
    return values
  end

  def curation_notes_admin=( values )
    self.curation_notes_admin_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: curation_notes_admin_ordered, values: values )
    super values
  end

  # the list of curation_notes_user is ordered
  def curation_notes_user
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: curation_notes_user_ordered, values: values )
    return values
  end

  def curation_notes_user=( values )
    self.curation_notes_user_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: curation_notes_user_ordered, values: values )
    super values
  end

  # end metadata

end
