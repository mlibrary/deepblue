# frozen_string_literal: true

module Deepblue

  class MetadataError < RuntimeError
  end

  module MetadataBehavior

    mattr_accessor :metadata_behavior_debug_verbose,
                   default: ::Deepblue::MetadataBehaviorIntegrationService.metadata_behavior_debug_verbose

    mattr_accessor :metadata_field_sep,
                   default: ::Deepblue::MetadataBehaviorIntegrationService.metadata_field_sep
    mattr_accessor :metadata_report_default_depth,
                   default: ::Deepblue::MetadataBehaviorIntegrationService.metadata_report_default_depth
    mattr_accessor :metadata_report_default_filename_post,
                   default: ::Deepblue::MetadataBehaviorIntegrationService.metadata_report_default_filename_post
    mattr_accessor :metadata_report_default_filename_ext,
                   default: ::Deepblue::MetadataBehaviorIntegrationService.metadata_report_default_filename_ext

    def add_curation_note_admin( note: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.curation_notes_admin=#{self.curation_notes_admin}",
                                             "note=#{note}",
                                             "" ] if metadata_behavior_debug_verbose
      self.date_modified = DateTime.now # touch it so it will save updated attributes
      notes = self.curation_notes_admin
      notes = [] if notes.nil?
      self.curation_notes_admin = notes << note
      save!
    end

    def add_curation_note_user( note: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.curation_notes_user=#{self.curation_notes_user}",
                                             "note=#{note}",
                                             "" ] if metadata_behavior_debug_verbose
      self.date_modified = DateTime.now # touch it so it will save updated attributes
      notes = self.curation_notes_user
      notes = [] if notes.nil?
      self.curation_notes_user = notes << note
      save!
    end

    def for_metadata_id
      self.id
    end

    def for_metadata_route
      "route to #{id}"
    end

    def for_metadata_state
      self.state
    end

    def for_metadata_title
      self.title
    end

    def for_metadata_workflow_state
      self.workflow_state
    end

    def metadata_keys_all
      %i[]
    end

    def metadata_keys_report
      %i[]
    end

    def metadata_keys_brief
      %i[]
    end

    def metadata_hash( metadata_keys:, ignore_blank_values:, **key_values )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "metadata_keys=#{metadata_keys}",
                                             "ignore_blank_values=#{ignore_blank_values}",
                                             "key_values=#{key_values}",
                                             "" ] if metadata_behavior_debug_verbose
      return {} if metadata_keys.blank?
      key_values = {} if key_values.nil?
      metadata_keys.each do |key|
        next if metadata_hash_override( key: key, ignore_blank_values: ignore_blank_values, key_values: key_values )
        value = case key.to_s
                when 'id'
                  for_metadata_id
                when 'location'
                  for_metadata_route
                when 'route'
                  for_metadata_route
                when 'state'
                  for_metadata_state
                when 'title'
                  for_metadata_title
                when 'visibility'
                  metadata_report_visibility_value( self.visibility )
                when 'workflow_state'
                  for_metadata_workflow_state
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

    def metadata_report( dir: nil,
                         out: nil,
                         depth: metadata_report_default_depth,
                         filename_pre: '',
                         filename_post: metadata_report_default_filename_post,
                         filename_ext: metadata_report_default_filename_ext )

      raise MetadataError, "Either dir: or out: must be specified." if dir.nil? && out.nil?
      if out.nil?
        target_file = metadata_report_filename( pathname_dir: dir,
                                                filename_pre: filename_pre,
                                                filename_post: filename_post,
                                                filename_ext: filename_ext )
        open( target_file, 'w' ) do |out2|
          metadata_report( out: out2, depth: depth )
        end
        return target_file
      else
        report_title = metadata_report_title( depth: depth )
        out.puts report_title
        ignore_blank_values, metadata_keys = metadata_report_keys
        metadata = metadata_hash( metadata_keys: metadata_keys, ignore_blank_values: ignore_blank_values )
        metadata_report_to( out: out, metadata_hash: metadata, depth: depth )
        # Don't include metadata reports for contained objects, such as file_sets
        # contained_objects = metadata_report_contained_objects
        # if contained_objects.count.positive?
        #   contained_objects.each do |obj|
        #     next unless obj.respond_to? :metadata_report
        #     out.puts
        #     obj.metadata_report( out: out, depth: depth + 1 )
        #   end
        # end
        return nil
      end
    end

    def metadata_report_contained_objects
      []
    end

    def metadata_report_filename( pathname_dir:,
                                  filename_pre:,
                                  filename_post: metadata_report_default_filename_post,
                                  filename_ext: metadata_report_default_filename_ext )

      pathname_dir.join "#{filename_pre}#{for_metadata_id}#{filename_post}#{filename_ext}"
    end

    def metadata_report_keys
      return AbstractEventBehavior::IGNORE_BLANK_KEY_VALUES, metadata_keys_report
    end

    def metadata_report_label( metadata_key:, metadata_value: )
      return nil if metadata_key.blank?
      label = metadata_report_label_override(metadata_key: metadata_key, metadata_value: metadata_value )
      return label if label.present?
      label = case metadata_key.to_s
              when 'id'
                'ID: '
              when 'location'
                'Location: '
              when 'route'
                'Route: '
              when 'title'
                'Title: '
              when 'visibility'
                'Visibility: '
              else
                "#{metadata_key.to_s.titlecase}: "
              end
      label
    end

    # override this if there is anything extra to add
    # return nil if not handled
    def metadata_report_label_override( metadata_key:, metadata_value: ) # rubocop:disable Lint/UnusedMethodArgument
      label = nil
      return label
    end

    def metadata_report_title( depth:,
                               header_begin: '=',
                               header_end: '=' )

      report_title = for_metadata_title
      report_title = report_title.join( metadata_report_title_field_sep ) if report_title.respond_to? :join
      if depth.positive?
        "#{header_begin * depth} #{metadata_report_title_pre}#{report_title} #{header_end * depth}"
      else
        "#{metadata_report_title_pre}#{report_title}"
      end
    end

    def metadata_report_title_pre
      ''
    end

    def metadata_report_title_field_sep
      ' '
    end

    def metadata_report_to( out:, metadata_hash:, depth: 0 )
      return if out.nil?
      metadata_hash.each_pair do |key, value|
        metadata_report_item_to( out: out, key: key, value: value, depth: depth )
      end
    end

    def metadata_report_item_to( out:, key:, value:, depth: ) # rubocop:disable Lint/UnusedMethodArgument
      label = metadata_report_label(metadata_key: key, metadata_value: value )
      MetadataHelper.report_item( out, label, value )
    end

    def metadata_report_visibility_value( visibility )
      case visibility
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        'published'
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        'private'
      else
        visibility
      end
    end

  end

end
