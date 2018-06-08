# frozen_string_literal: true

class FileSet < ActiveFedora::Base
  include ::Deepblue::FileSetMetadata # must be before `include ::Hyrax::FileSetBehavior`
  include ::Hyrax::FileSetBehavior
  include ::Deepblue::FileSetBehavior
  include ::Deepblue::ProvenanceBehavior

  def attributes_all_for_provenance
    %i[
      date_created
      date_modified
      date_uploaded
      file_extension
      files_count
      label
      location
      mime_type
      original_checksum
      original_name
      parent_id
      uri
      visibility
    ]
  end

  def attributes_brief_for_provenance
    %i[
      label
      parent_id
      file_extension
      visibility
    ]
  end

  def files_to_file
    files.each do |f|
      return f if f.original_name.present?
    end
    nil
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
                value = original_checksum
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

end
