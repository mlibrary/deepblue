# frozen_string_literal: true

module Deepbluedocs

  module DissertationWorkFormBehavior
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

      self.terms += [ :description_thesisdegreediscipline, :date_submitted, :contributor_advisor, :contributor_committeemember, :description_thesisdegreegrantor, :identifier, :identifier_orcid, :type_none, :type_snre, :subject_other, :language_none, :contributor_author, :identifier_uniqname, :description_thesisdegreename, :date_uploaded, :date_modified, :academic_affiliation, :alt_title, :description_abstract, :license, :resource_type, :date_available, :date_copyright, :date_issued, :date_collected, :date_valid, :date_reviewed, :date_accepted, :degree_level, :degree_name, :degree_field, :replaces, :hydrologic_unit_code, :funding_body, :funding_statement, :in_series, :tableofcontents, :bibliographic_citation, :peerreviewed, :additional_information, :digitization_spec, :file_extent, :file_format, :dspace_community, :dspace_collection, :isbn, :issn, :embargo_reason, :conference_location, :conference_name, :conference_section]

      self.required_fields += [:resource_type, :identifier_uniqname, :description_thesisdegreename, :description_thesisdegreediscipline, :date_issued, :date_submitted, :contributor_advisor, :contributor_committeemember, :description_abstract, :description_thesisdegreegrantor]

      def primary_terms
        [:title, :identifier, :creator, :identifier_uniqname, :identifier_orcid, :description_thesisdegreename, :type_snre, :description_thesisdegreediscipline, :date_issued, :date_submitted, :contributor_advisor, :contributor_committeemember, :description_abstract, :keyword, :subject_other, :description_thesisdegreegrantor, :rights_statement] 
      end

      def secondary_terms
        t = [:language_none, :date_available]
        # jose admin?  not found byebug
        #t << [:keyword, :source, :funding_body, :dspace_community, :dspace_collection] if current_ability.current_user.admin?
        t.flatten
      end

      def self.date_terms
        [
          :date_created,
          :date_available,
          :date_copyright,
          :date_issued,
          :date_collected,
          :date_valid,
          :date_reviewed,
          :date_accepted,
        ]
      end

      def date_terms
        self.class.date_terms
      end

      def self.build_permitted_params
        super + self.date_terms + [:degree_level, :degree_name, :degree_field] + [:embargo_reason] + [
          {
            :nested_geo_attributes => [:id, :_destroy, :point_lat, :point_lon, :bbox_lat_north, :bbox_lon_west, :bbox_lat_south, :bbox_lon_east, :label, :point, :bbox],
            :nested_related_items_attributes => [:id, :_destroy, :label, :related_url]
          }
        ] + [
            {
                :other_affiliation_other => [],
                :degree_field_other => [],
                :degree_name_other => []
            }
        ]
      end
    end
  end

end
