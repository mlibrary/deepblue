module Hyrax
  module Renderers

    # This is used by PresentsAttributes to show licenses
    #   e.g.: presenter.attribute_to_html(:doi, render_as: :doi)
    class ChecksumAttributeRenderer < AttributeRenderer

      mattr_accessor :checksum_attribute_renderer_debug_verbose, default: false

      def attribute_value_to_html(value)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value=#{value}",
                                               "options=#{options}",
                                               "" ] if checksum_attribute_renderer_debug_verbose
        rv = if options[:algorithm].present?
               "#{value}/#{options[:algorithm]}"
             else
               value
             end
        rv = 'nbsp;' if rv.blank? && options[:include_empty]
        return rv
      end

    end

  end
end
