# frozen_string_literal: true
# Reviewed: hyrax4

module Hyrax
  module FactoryHelpers
    module_function

    # def mock_file_factory(opts = {})
    #   mock_model('MockOriginal',
    #              mime_type:         opts.fetch(:mime_type, 'text/plain'),
    #              content:           opts.fetch(:content, 'content'),
    #              file_size:         opts.fetch(:file_size, []),
    #              format_label:      opts.fetch(:format_label, []),
    #              height:            opts.fetch(:height, []),
    #              width:             opts.fetch(:width, []),
    #              filename:          opts.fetch(:filename, []),
    #              well_formed:       opts.fetch(:well_formed, []),
    #              page_count:        opts.fetch(:page_count, []),
    #              file_title:        opts.fetch(:file_title, []),
    #              last_modified:     opts.fetch(:last_modified, []),
    #              original_checksum: opts.fetch(:original_checksum, []),
    #              digest:            opts.fetch(:digest, []),
    #              duration:          opts.fetch(:duration, []),
    #              sample_rate:       opts.fetch(:sample_rate, []))
    # end

    FIELDS = { mime_type: 'text/plain',
               content: 'content',
               file_size: [],
               format_label: [],
               height: [],
               width: [],
               filename: [],
               well_formed: [],
               page_count: [],
               file_title: [],
               last_modified: [],
               original_checksum: [],
               alpha_channels: [],
               digest: [],
               duration: [],
               sample_rate: [],
               versions: [] }.freeze

    def mock_file_factory(opts = {})
      fields = FIELDS.each_with_object({}) do |(name, default), hsh|
        hsh[name] = opts.fetch(name, default)
      end

      mock_model('MockOriginal', fields)
    end

    # as defined in Hyrax::FileMetadata
    HYRAX_FILE_METADATA_FIELDS = { file_identifier: '',
                                   alternate_ids: [],
                                   file_set_id: '',
                                   label: [''],
                                   original_filename: '',
                                   mime_type: 'text/plain',
                                   type: [],
                                   format_label: [],
                                   size: [],
                                   well_formed: [],
                                   valid: [],
                                   date_created: [],
                                   fits_version: [],
                                   exif_version: [],
                                   checksum: [],
                                   frame_rate: [],
                                   bit_rate: [],
                                   duration: [],
                                   sample_rate: [],
                                   height: [],
                                   width: [],
                                   bit_depth: [],
                                   channels: [],
                                   data_format: [],
                                   offset: [],
                                   file_title: [],
                                   creator: [],
                                   page_count: [],
                                   language: [],
                                   word_count: [],
                                   character_count: [],
                                   line_count: [],
                                   character_set: [],
                                   markup_basis: [],
                                   markup_language: [],
                                   paragraph_count: [],
                                   table_count: [],
                                   graphics_count: [],
                                   byte_order: [],
                                   compression: [],
                                   color_space: [],
                                   profile_name: [],
                                   profile_version: [],
                                   orientation: [],
                                   color_map: [],
                                   image_producer: [],
                                   capture_device: [],
                                   scanning_software: [],
                                   gps_timestamp: [],
                                   latitude: [],
                                   longitude: [],
                                   aspect_ratio: [] }.freeze

    def mock_file_metadata_factory(opts = {})
      fields = HYRAX_FILE_METADATA_FIELDS.each_with_object({}) do |(name, default), hsh|
        hsh[name] = opts.fetch(name, default)
      end

      mock_model('MockFileMetadata', fields)
    end
  end
end
