# Generated via
#  `rails generate hyrax:work DataSet`
module Hyrax
  # Generated form for DataSet
  class DataSetForm < Hyrax::Forms::WorkForm

  	include Deepbluedocs::DefaultWorkFormBehavior
    
    self.model_class = ::DataSet

    #include HydraEditor::Form::Permissions
    #self.terms += [:date_coverage]
    # self.required_fields = [ :creator,
    #                          :description,
    #                          :methodology,
    #                          :rights_statement,
    #                          :subject,
    #                          :title ]
    #
    # def rendered_terms
    #   [ :creator,
    #     :description,
    #     :fundedby,
    #     :grantnumber,
    #     :isReferencedBy,
    #     :keyword,
    #     :language,
    #     :methodology,
    #     :on_behalf_of,
    #     :resource_type,
    #     :rights_statement,
    #     :subject,
    #     :title,
    #     :visibility ]
    # end

    self.terms += [ :authoremail, :date_coverage, :description, :keyword ]
    self.required_fields += [ :authoremail, :description, :rights_statement ]
    self.default_work_primary_terms -=
        [
            :abstract,
            :license,
            :alt_title,
            :dates_section,
            :degree_level,
            :degree_name,
            :degree_field,
            :bibliographic_citation,
            :academic_affiliation,
            :in_series,
            :tableofcontents,
        ]

    self.default_work_primary_terms += [ :authoremail, :date_coverage, :description, :keyword ]

    self.default_work_secondary_terms -=
        [
            :hydrologic_unit_code,
            :geo_section,
            :funding_statement,
            :publisher,
            :peerreviewed,
            :conference_location,
            :conference_name,
            :conference_section,
            :language,
            :file_format,
            :file_extent,
            :digitization_spec,
            :replaces,
            :isbn,
            :issn
        ]

  end

end
