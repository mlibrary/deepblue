# Generated via
#  `rails generate hyrax:work DataSet`
module Hyrax
  # Generated form for DataSet
  class DataSetForm < Hyrax::Forms::WorkForm
  	include Deepbluedocs::DefaultWorkFormBehavior
    
    self.model_class = ::DataSet

    #self.terms += [:resource_type]

    #include HydraEditor::Form::Permissions
    self.terms += [:resource_type] #, :date_coverage]
    # self.required_fields = [ #:authoremail,
    #                          :creator,
    #                          :description,
    #                          :methodology,
    #                          :rights_statement,
    #                          :subject,
    #                          :title ]
    #
    # def rendered_terms
    #   [ #:authoremail,
    #     :creator,
    #     #:date_coverage,
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

  end

end
