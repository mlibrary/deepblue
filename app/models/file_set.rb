# frozen_string_literal: true

class FileSet < ActiveFedora::Base

  include ::Deepblue::FileSetMetadata # must be before `include ::Hyrax::FileSetBehavior`
  include ::Hyrax::FileSetBehavior
  include ::Deepblue::FileSetBehavior
  include ::Deepblue::MetadataBehavior
  include ::Deepblue::ProvenanceBehavior

  before_destroy :provenance_before_destroy_file_set

  def provenance_before_destroy_file_set
    provenance_destroy( current_user: '' ) # , event_note: 'provenance_before_destroy_file_set' )
  end

  def metadata_keys_all
    %i[
      date_created
      date_modified
      date_uploaded
      extracted_text
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
      title
      uri
      visibility
    ]
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

  def attributes_all_for_provenance
    metadata_keys_all
  end

  def attributes_brief_for_provenance
    metadata_keys_brief
  end

  def files_to_file
    return nil unless files.present?
    files.each do |f|
      return f if f.original_name.present?
    end
    nil
  end

  def for_provenance_route
    Rails.application.routes.url_helpers.hyrax_file_set_path( id: id )
  end

  def map_provenance_attributes_override!( event:, # rubocop:disable Lint/UnusedMethodArgument
                                           attribute:,
                                           ignore_blank_key_values:,
                                           prov_key_values: )
    value = nil
    handled = case attribute.to_s
              when 'file_extension'
                value = File.extname label if label.present?
                true
              when 'files_count'
                value = files.size
                true
              when 'files_size'
                value = if file_size.blank?
                          original_file.size
                        else
                          file_size[0]
                        end
                true
              when 'files_size_human_readable'
                value = if file_size.blank?
                          original_file.size
                        else
                          file_size[0]
                        end
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
                value = original_file.original_name
                true
              when 'uri'
                value = uri.value
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
    handled = case metadata_key.to_s
              when 'file_extension'
                value = File.extname label if label.present?
                true
              when 'files_count'
                value = files.size
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
                value = original_file.original_name
                true
              when 'uri'
                value = uri.value
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

end
