# frozen_string_literal: true
# hyrax-orcid

# Universal methods to work out the names and terms for a work form
module Hyrax
  module Orcid
    module WorkFormNameHelper
      def meta_model
        raise NotImplementedError, "You must implement this method, and return a classname string i.e GenericWork"
      end

      def work_class
        @_work_class ||= meta_model.constantize
      end

      def work_form_class
        @_work_form_class ||= "Hyrax::#{meta_model}Form".constantize
      end

      def work_type_terms
        @_work_type_terms ||= work_form_class.terms
      end
    end
  end
end
