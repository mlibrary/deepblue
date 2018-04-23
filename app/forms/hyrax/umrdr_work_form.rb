# Generated via
#  `rails generate hyrax:work UmrdrWork`
module Hyrax
  # Generated form for UmrdrWork
  class UmrdrWorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::UmrdrWork
    #self.terms += [:resource_type]

    include HydraEditor::Form::Permissions
    self.terms += [:resource_type, :date_coverage]
    self.required_fields = [ :authoremail,
                             :creator,
                             :description,
                             :methodology,
                             :rights_statement,
                             :subject,
                             :title ]

    def rendered_terms
      [ :authoremail,
        :creator,
        :date_coverage,
        :description,
        :fundedby,
        :grantnumber,
        :isReferencedBy,
        :keyword,
        :language,
        :methodology,
        :on_behalf_of,
        :resource_type,
        :rights_statement,
        :subject,
        :title,
        :visibility ]
    end

  end
end
