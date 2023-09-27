module Hyrax
  module Renderers

    # This is used by PresentsAttributes to show depositors
    #   e.g.: presenter.attribute_to_html(:depositor, render_as: :depositor)
    class CreatorOrcidAttributeRenderer < AttributeRenderer

      mattr_accessor :creator_orcid_attribute_renderer_debug_verbose, default: false

      # Draw the table row for the attribute
      def render
        return '' if values.blank? && !options[:include_empty]
        puralized_label =
        markup = %(<tr><th>#{label}</th>\n<td><ul class='tabular'>\n)
        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "field=#{field}",
                                               "values=#{values}",
                                               "options=#{options}",
                                               "attributes=#{attributes}",
                                               "" ] if creator_orcid_attribute_renderer_debug_verbose
        attributes.delete(:itemscope) # remove :itemscope
        attributes.delete(:itemtype) # remove :itemtype
        if values.count <= 5
          markup += Array(values).map do |value|
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "value=#{value}",
                                                   "" ] if creator_orcid_attribute_renderer_debug_verbose
            %(<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</span></li>)
          end.join("\n")
        else
          markup += %(<li#{html_attributes(attributes)}>#{creator_orcids_compact}</li>)
        end
        markup += %(\n</ul></td></tr>)
        markup.html_safe
      end

      def attribute_value_to_html(value)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value=#{value}",
                                               "" ] if creator_orcid_attribute_renderer_debug_verbose
        value = "https://orcid.id/#{value}" unless ( value.start_with?('http:') || value.start_with?('https:') )
        value = value.sub( /http\:/, 'https:' ) if value.start_with?('http:')
        return %(<span itemprop="orcid">#{li_value(value)}</span>)
      end

      def creator_orcids_compact
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "values=#{values}",
                                               "" ] if creator_orcid_attribute_renderer_debug_verbose
        rv = []
        rv << %(<span itemprop="creator_orcid" class="moreauthor">)
        last = values.size - 1
        values.each_with_index do |author, index|
          if index < last
            rv << %(#{li_value(author)}; )
          else
            rv << %( , #{li_value(author)})
          end
        end
        rv << %(</span>)
        return rv.join("\n")
      end

    end

  end
end
