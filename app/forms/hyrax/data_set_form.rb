# frozen_string_literal: true

module Hyrax

  class DataSetForm < DeepblueForm

    self.model_class = ::DataSet

    self.terms -= %i[ rights_statement ]
    self.terms +=
      %i[
        authoremail
        date_coverage
        description
        fundedby
        grantnumber
        keyword
        methodology
        rights_license
        subject_discipline
      ]

    self.default_work_primary_terms =
      %i[
        title
        creator
        authoremail
        methodology
        description
        date_coverage
        rights_license
        subject_discipline
        fundedby
        grantnumber
        keyword
        language
        isReferencedBy
      ]

    self.required_fields =
      %i[
        title
        creator
        authoremail
        methodology
        description
        rights_license
        subject_discipline
      ]

    self.default_work_secondary_terms = []

  end

end
