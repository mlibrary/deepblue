# Generated via
#  `rails generate hyrax:work Doc`
module Hyrax
  # Generated form for Doc
  class DocForm < DeepblueForm
  	include Deepbluedocs::DocWorkFormBehavior

    self.model_class = ::Doc
    self.terms += [:resource_type]
  end
end