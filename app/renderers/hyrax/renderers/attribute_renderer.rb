# monkey override

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/renderers/hyrax/renderers/attribute_renderer.rb" )

module Hyrax
  module Renderers

    # monkey patch Hyrax::Renderers::AttributeRenderer
    class AttributeRenderer
      # TODO: add support for multiple work_types in options

      mattr_accessor :attribute_renderer_debug_verbose, default: false

      # Draw the table row for the attribute
      def render
        # begin monkey
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "field=#{field}",
                                               "values=#{values}",
                                               "options=#{options}",
                                               "" ] if attribute_renderer_debug_verbose
        # end monkey
        return '' if values.blank? && !options[:include_empty]
        markup = []
        markup << %(<span itemprop="#{options[:itemprop]}">) if options[:itemprop].present?
        markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)
        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")
        Array(values).each do |value|
          # begin monkey
          value_str = ::Deepblue::MetadataHelper.str_normalize_encoding value.to_s
          markup << "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value_str)}</li>"
          # end monkey
        end
        markup << %(</ul></td></tr>)
        markup << %(</span>) if options[:itemprop].present?
        markup.join("\n").html_safe
      end

      # Draw the dt row for the attribute
      def render_dt_row
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "field=#{field}",
                                               "values=#{values}",
                                               "options=#{options}",
                                               "" ] if attribute_renderer_debug_verbose
        markup = ''
        return markup if values.blank? && !options[:include_empty]
        markup << %(<dt>#{label}</dt>\n<dd>)
        attributes = microdata_object_attributes(field).merge(class: "attribute attribute-#{field}")
        Array(values).each_with_index do |value,index|
          markup << %(<br/>\n) if index > 0
          markup << %(#{attribute_value_to_html(value.to_s)})
          markup << %(&nbsp;) if value.blank?
        end
        markup << %(</dd>)
        markup.html_safe
      end

    end

  end
end
