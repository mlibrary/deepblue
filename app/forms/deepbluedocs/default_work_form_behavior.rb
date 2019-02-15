# frozen_string_literal: true

module Deepbluedocs

  module DefaultWorkFormBehavior
    extend ActiveSupport::Concern
    included do
      # include ScholarsArchive::DateTermsBehavior
      # include ScholarsArchive::NestedBehavior

      # accessor attributes only used to group dates and geo fields and allow proper ordering in this form
      attr_accessor :dates_section
      attr_accessor :geo_section

      attr_accessor :other_affiliation_other
      attr_accessor :degree_level_other
      attr_accessor :degree_field_other
      attr_accessor :degree_name_other

      # order isn't significant for self.terms
      self.terms += %i[
        academic_affiliation
        additional_information
        alt_title
        bibliographic_citation
        conference_location
        conference_name
        conference_section
        date_accepted
        date_available
        date_collected
        date_copyright
        date_issued
        date_modified
        date_reviewed
        date_uploaded
        date_valid
        degree_field
        degree_level
        degree_name
        description_abstract
        digitization_spec
        dspace_collection
        dspace_community
        embargo_reason
        file_extent
        file_format
        funding_body
        funding_statement
        hydrologic_unit_code
        in_series
        isbn
        issn
        license
        peerreviewed
        replaces
        resource_type
        tableofcontents
      ]

      self.required_fields += [:resource_type]
      self.required_fields -= [:keyword]

      class_attribute :default_work_primary_terms
      # TODO: is order significant self.default_work_primary_terms?
      self.default_work_primary_terms =
        %i[
          title
          alt_title
          creator
          contributor
          description_abstract
          license
          resource_type
          identifier
          dates_section
          degree_level
          degree_name
          degree_field
          bibliographic_citation
          academic_affiliation
          in_series
          subject
          tableofcontents
          rights_statement
        ]

      class_attribute :default_work_secondary_terms
      # TODO: is order significant self.default_work_secondary_terms?
      self.default_work_secondary_terms =
        %i[
          hydrologic_unit_code
          geo_section
          funding_statement
          publisher
          peerreviewed
          conference_location
          conference_name
          conference_section
          language
          file_format
          file_extent
          digitization_spec
          replaces
          additional_information
          isbn
          issn
        ]

      def primary_terms
        if current_ability.admin?
          default_work_primary_terms | super
          default_work_primary_terms.delete(:curation_notes_admin)
          default_work_primary_terms.delete(:curation_notes_user)
          default_work_primary_terms << :curation_notes_admin
          default_work_primary_terms << :curation_notes_user
          default_work_primary_terms
        else  
          default_work_primary_terms | super
          default_work_primary_terms.delete(:curation_notes_admin)
          default_work_primary_terms.delete(:curation_notes_user)
          default_work_primary_terms
        end
      end

      def secondary_terms
        t = default_work_secondary_terms
        # jose admin?  not found byebug
        # t << [:keyword, :source, :funding_body, :dspace_community, :dspace_collection] if current_ability.current_user.admin?
        t.flatten
      end

      def self.date_terms
        %i[
          date_created
          date_available
          date_copyright
          date_issued
          date_collected
          date_valid
          date_reviewed
          date_accepted
        ]
      end

      def date_terms
        self.class.date_terms
      end

      def self.build_permitted_params
        super + date_terms + %i[degree_level degree_name degree_field] + [:embargo_reason] + [
          {
            nested_geo_attributes: %i[id
                                      _destroy
                                      point_lat
                                      point_lon
                                      bbox_lat_north
                                      bbox_lon_west
                                      bbox_lat_south
                                      bbox_lon_east
                                      label
                                      point
                                      bbox],
            nested_related_items_attributes: %i[id _destroy label related_url]
          }
        ] + [
          {
            other_affiliation_other: [],
            degree_field_other: [],
            degree_name_other: []
          }
        ]
      end
    end
  end

end
