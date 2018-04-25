# Generated via
#  `rails generate hyrax:work Dissertation`
module Hyrax
  # Generated form for Dissertation
  class DissertationForm < Hyrax::Forms::WorkForm
  	include Deepbluedocs::DissertationWorkFormBehavior

    self.model_class = ::Dissertation
    self.terms += [:resource_type]
  end
end
