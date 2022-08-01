module Hyrax
  module Renderers

    # This is used by PresentsAttributes to show depositors
    #   e.g.: presenter.attribute_to_html(:depositor, render_as: :depositor)
    class FundedbyOtherAttributeRenderer < AttributeRenderer
      include Hyrax::HyraxHelperBehavior

      mattr_accessor :fundedby_other_attribute_renderer_debug_verbose, default: false

      # Draw the table row for the attribute
      def render
        return '' if values.blank? && !options[:include_empty]

        markup = []
        markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular_list'>)
        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "attributes=#{attributes}",
                                               "" ] if fundedby_other_attribute_renderer_debug_verbose

        values.each_with_index do |value, index|
          markup << %(<li#{html_attributes(attributes)}>)
          attribute_value_index_to_html(markup, value.to_s, index, values.size)
        end
        markup << %(\n</ul></td></tr>)
        markup.join("\n").html_safe
      end

      def attribute_value_index_to_html(markup, value, index, max_index)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value=#{value}",
                                               "index=#{index}",
                                               "" ] if fundedby_other_attribute_renderer_debug_verbose
        markup << %(<span itemprop="#{field}" class="more">#{iconify_auto_link(value)}</span>)
        if index < max_index - 1
          markup << %(<p></p>)
        end
        markup << %(</li>)
      end

    end

  end
end
