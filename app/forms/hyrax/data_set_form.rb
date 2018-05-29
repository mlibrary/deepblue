# frozen_string_literal: true

module Hyrax

  class DataSetForm < DeepblueForm

    self.model_class = ::DataSet

    self.terms += %i[authoremail date_coverage description keyword]
    self.required_fields += %i[authoremail description rights_license]
    self.default_work_primary_terms -=
      %i[
        abstract
        license
        alt_title
        dates_section
        degree_level
        degree_name
        degree_field
        bibliographic_citation
        academic_affiliation
        in_series
        tableofcontents
        rights_statement
      ]

    self.default_work_primary_terms += %i[authoremail date_coverage description keyword rights_license]

    self.default_work_secondary_terms -=
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
        isbn
        issn
      ]

  end

end
