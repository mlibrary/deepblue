# Generated via
#  `rails generate hyrax:work DataSet`
module Hyrax
  # Generated form for DataSet
  class DataSetForm < Hyrax::Forms::WorkForm
  	include Deepbluedocs::DefaultWorkFormBehavior
    
    self.model_class = ::DataSet
    self.terms += [:resource_type]
  end
end
