# frozen_string_literal: true

module Hyrax

  # TODO: monkey patch this to only override and provide necessary behavior
  module CharacterizationBehavior
    extend ActiveSupport::Concern

    class_methods do

      def characterization_terms
        [
          :byte_order,
          :compression,
          :height,
          :width,
          :height,
          :color_space,
          :profile_name,
          :profile_version,
          :orientation,
          :color_map,
          :image_producer,
          :capture_device,
          :scanning_software,
          :gps_timestamp,
          :latitude,
          :longitude,
          :file_format,
          :file_title,
          :page_count,
          :duration,
          :sample_rate,
          :format_label,
          # :file_size, # replace this with
          :file_size_human_readable, # replaces file size
          :filename,
          :well_formed,
          :last_modified,
          :original_checksum, # TODO: revisit this...
          :mime_type
        ]
      end

      def characterization_terms_admin_only
        %i[
          virus_scan_service
          virus_scan_status
          virus_scan_status_date
        ]
      end

    end

    included do
      delegate( *characterization_terms, to: :solr_document )
      delegate( *characterization_terms_admin_only, to: :solr_document )
    end

    def characterized?
      !characterization_metadata.values.compact.empty?
    end

    def characterization_metadata
      @characterization_metadata ||= build_characterization_metadata
    end

    def characterization_metadata_admin_only
      @characterization_metadata_admin_only ||= build_characterization_metadata_admin_only
    end

    # Override this if you want to inject additional characterization metadata
    # Use a hash of key/value pairs where the value is an Array or String
    # {
    #   term1: ["value"],
    #   term2: ["value1", "value2"],
    #   term3: "a string"
    # }
    def additional_characterization_metadata
      @additional_characterization_metadata ||= {}
    end

    def additional_characterization_metadata_admin_only
      @additional_characterization_metadata_admin_only ||= {}
    end

    def label_for_term( term )
      MsgHelper.t( "show.file_set.label.#{term}", raise: true )
    rescue I18n::MissingTranslationData => e
      term.to_s.titleize
    end

    # Returns an array of characterization values truncated to 250 characters limited
    # to the maximum number of configured values.
    # @param [Symbol] term found in the characterization_metadata hash
    # @return [Array] of truncated values
    def primary_characterization_values( term )
      values = values_for( term )
      values.slice!(Hyrax.config.fits_message_length, (values.length - Hyrax.config.fits_message_length))
      truncate_all(values)
    end

    # Returns an array of characterization values truncated to 250 characters limited
    # to the maximum number of configured values.
    # @param [Symbol] term found in the characterization_metadata hash
    # @return [Array] of truncated values
    def primary_characterization_values_admin_only( term )
      values = values_for_admin_only( term )
      values.slice!(Hyrax.config.fits_message_length, (values.length - Hyrax.config.fits_message_length))
      truncate_all(values)
    end

    # Returns an array of characterization values truncated to 250 characters that are in
    # excess of the maximum number of configured values.
    # @param [Symbol] term found in the characterization_metadata hash
    # @return [Array] of truncated values
    def secondary_characterization_values(term)
      values = values_for(term)
      additional_values = values.slice(Hyrax.config.fits_message_length, values.length - Hyrax.config.fits_message_length)
      return [] unless additional_values
      truncate_all(additional_values)
    end

    # Returns an array of characterization values truncated to 250 characters that are in
    # excess of the maximum number of configured values.
    # @param [Symbol] term found in the characterization_metadata hash
    # @return [Array] of truncated values
    def secondary_characterization_values_admin_only(term)
      values = values_for_admin_only(term)
      additional_values = values.slice(Hyrax.config.fits_message_length, values.length - Hyrax.config.fits_message_length)
      return [] unless additional_values
      truncate_all(additional_values)
    end

    private

      def values_for( term )
        Array.wrap( characterization_metadata[term] )
      end

      def values_for_admin_only( term )
        Array.wrap( characterization_metadata_admin_only[term] )
      end

      def truncate_all(values)
        values.map { |v| v.to_s.truncate(250) }
      end

      def build_characterization_metadata
        self.class.characterization_terms.each do |term|
          value = send(term)
          additional_characterization_metadata[term.to_sym] = value if value.present?
        end
        additional_characterization_metadata
      end

      def build_characterization_metadata_admin_only
        self.class.characterization_terms_admin_only.each do |term|
          value = send(term)
          additional_characterization_metadata_admin_only[term.to_sym] = value if value.present?
        end
        additional_characterization_metadata_admin_only
      end

  end

end
