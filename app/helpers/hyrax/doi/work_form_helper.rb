# frozen_string_literal: true
module Hyrax
  module Doi
    module WorkFormHelper
      def form_tabs_for(form:)
        if form.model_class.ancestors.include? ::Deepblue::DoiBehavior
          super.prepend("doi")
        else
          super
        end
      end
    end
  end
end
