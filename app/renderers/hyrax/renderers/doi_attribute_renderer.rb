module Hyrax
  module Renderers

    # This is used by PresentsAttributes to show a doi
    #   e.g.: presenter.attribute_to_html(:doi, render_as: :doi)
    class DoiAttributeRenderer < AttributeRenderer

      mattr_accessor :doi_attribute_renderer_debug_verbose, default: false

      ##
      # Special treatment for doi.
      def attribute_value_to_html(value)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value=#{value}",
                                               "" ] if doi_attribute_renderer_debug_verbose
        rv = if value == ::Deepblue::DoiBehavior.doi_pending
               value
             elsif value.start_with? 'http'
               value
             else
               value.sub 'doi:', 'https://doi.org/'
             end
        return rv
      end

    end

  end
end
