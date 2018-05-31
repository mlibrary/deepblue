# frozen_string_literal: true

module Hyrax

  class DataSetForm < DeepblueForm

    self.model_class = ::DataSet

    self.terms -= %i[ rights_statement ]
    self.terms += %i[ authoremail date_coverage description keyword rights_license ]

    self.required_fields -= %i[ rights_statement ]
    self.required_fields += %i[ authoremail description rights_license ]

    self.default_work_primary_terms -=
      %i[
        abstract
        academic_affiliation
        alt_title
        bibliographic_citation
        dates_section
        degree_field
        degree_level
        degree_name
        in_series
        license
        rights_statement
        tableofcontents
      ]
    self.default_work_primary_terms += %i[ authoremail date_coverage description keyword rights_license ]

    self.default_work_secondary_terms -=
      %i[
        conference_location
        conference_name
        conference_section
        digitization_spec
        file_extent
        file_format
        funding_statement
        geo_section
        hydrologic_unit_code
        isbn
        issn
        language
        peerreviewed
        publisher
        replaces
      ]

  end

end
