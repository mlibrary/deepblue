module Hyrax
  module Renderers

    # This is used by PresentsAttributes to show depositors
    #   e.g.: presenter.attribute_to_html(:depositor, render_as: :depositor)
    class CreatorAttributeRenderer < FacetedAttributeRenderer

      mattr_accessor :creator_attribute_renderer_debug_verbose, default: false

      def self.render_for_collection( links )
        lines = []
        if 5 >= links.count
          lines << %(<span itemprop="creator" class="moreauthor">)
          last = links.size - 1
          links.each_with_index do |link, index|
            if index < last
              lines << %(<span itemprop="name">#{link}</span>; )
            else
              lines << %( and <span itemprop="name">#{link}</span>)
            end
          end
          lines << %(</span>)
        else
          links.each do |link|
            lines << %(<span itemprop="creator">)
            lines << %(<span itemprop="name">#{link}</span>)
            lines << %(</span><br/>)
          end
        end
        markup = lines.join("\n")
        # markup.html_safe
        return markup
      rescue Exception => e
        ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "e=#{e}" ] + e.backtrace
        return "Exception #{e}"
      end

      # Draw the table row for the attribute
      def render
        return '' if values.blank? && !options[:include_empty]

        markup = %(<tr><th>#{label}</th>\n<td><ul class='tabular'>\n)

        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "field=#{field}",
                                               "values=#{values}",
                                               "options=#{options}",
                                               "attributes=#{attributes}",
                                               "" ] if creator_attribute_renderer_debug_verbose
        attributes.delete(:itemscope) # remove :itemscope
        attributes.delete(:itemtype) # remove :itemtype
        if values.count <= 5
          markup += Array(values).map do |value|
            %(<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</span></li>)
          end.join("\n")
        else
          markup += %(<li#{html_attributes(attributes)}>#{creators_compact}</li>)
        end

        markup += %(\n</ul></td></tr>)

        markup.html_safe
      end

      def attribute_value_to_html(value)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value=#{value}",
                                               "" ] if creator_attribute_renderer_debug_verbose
        return %(<span itemprop="name">#{li_value(value)}</span>)
      end

      def creators_compact
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "values=#{values}",
                                               "" ] if creator_attribute_renderer_debug_verbose
        rv = []
        rv << %(<span itemprop="creator" class="moreauthor">)
        last = values.size - 1
        values.each_with_index do |author, index|
          if index < last
            rv << %(#{li_value(author)}; )
          else
            rv << %( and #{li_value(author)})
          end
        end
        rv << %(</span>)
        return rv.join("\n")
      end

    end

  end
end
