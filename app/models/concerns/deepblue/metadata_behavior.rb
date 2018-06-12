# frozen_string_literal: true

module Deepblue

  class MetadataError < RuntimeError
  end

  module MetadataBehavior

    def for_metadata_route
      "route to #{id}"
    end

    def metadata_keys_all
      %i[]
    end

    def metadata_keys_brief
      %i[]
    end

    def metadata_hash( metadata_keys:, ignore_blank_values:, **key_values )
      return {} if metadata_keys.blank?
      key_values = {} if key_values.nil?
      metadata_keys.each do |key|
        next if metadata_hash_override( key: key, ignore_blank_values: ignore_blank_values, key_values: key_values )
        value = case key.to_s
                when 'id'
                  id
                when 'location'
                  for_metadata_route
                when 'route'
                  for_metadata_route
                else
                  self[key]
                end
        value = '' if value.nil?
        if ignore_blank_values
          key_values[key] = value if value.present?
        else
          key_values[key] = value
        end
      end
      key_values
    end

    # override this if there is anything extra to add
    # return true if handled
    def metadata_hash_override( key:, ignore_blank_values:, key_values: ) # rubocop:disable Lint/UnusedMethodArgument
      handled = false
      return handled
    end

    def metadata_label( metadata_key:, metadata_value: )
      return nil if metadata_key.blank?
      label = metadata_label_override( metadata_key: metadata_key, metadata_value: metadata_value )
      return nil if label.nil?
      label = case metadata_key.to_s
              when 'id'
                'ID'
              else
                metadata_key.to_s.titlecase
              end
      label
    end

    # override this if there is anything extra to add
    # return nil if not handled
    def metadata_label_override( metadata_key:, metadata_value: ) # rubocop:disable Lint/UnusedMethodArgument
      label = nil
      return label
    end

    def metadata_report_to( out:, metadata_hash:, depth: 0 )
      return if out.nil?
      metadata_hash.each_pair do |key, value|
        metadata_report_item_to( out: out, key: key, value: value, depth: depth )
      end
    end

    def metadata_report_item_to( out:, key:, value:, depth: ) # rubocop:disable Lint/UnusedMethodArgument
      label = metadata_label( metadata_key: key, metadata_value: value )
      MetadataHelper.report_item( out, label, value )
    end

  end

end
