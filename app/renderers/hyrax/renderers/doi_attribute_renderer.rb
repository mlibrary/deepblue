module Hyrax
  module Renderers

    # This is used by PresentsAttributes to show licenses
    #   e.g.: presenter.attribute_to_html(:doi, render_as: :doi)
    class DoiAttributeRenderer < AttributeRenderer
      private

        ##
        # Special treatment for doi.
        def attribute_value_to_html(value)
          rv = if value == ::Deepblue::DoiBehavior.doi_pending
                 value
               elsif value.start_with? 'http'
                 value
               else
                 value.sub! 'doi:', 'https://doi.org/'
               end
          return rv
        end
    end

  end
end
