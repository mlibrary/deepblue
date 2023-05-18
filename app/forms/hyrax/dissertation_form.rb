# frozen_string_literal: true

module Hyrax
  # Generated form for Dissertation
  class DissertationForm < DeepblueForm
    include Deepbluedocs::DissertationWorkFormBehavior

    self.model_class = ::Dissertation
    self.terms += [:resource_type]
  end
end
