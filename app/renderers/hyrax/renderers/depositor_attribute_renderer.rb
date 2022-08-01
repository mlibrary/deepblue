module Hyrax
  module Renderers

    # This is used by PresentsAttributes to show depositors
    #   e.g.: presenter.attribute_to_html(:depositor, render_as: :depositor)
    class DepositorAttributeRenderer < AttributeRenderer

      mattr_accessor :depositor_attribute_renderer_debug_verbose, default: false

      def attribute_value_to_html(value)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value=#{value}",
                                               "" ] if depositor_attribute_renderer_debug_verbose
        # <% presenter.depositor.gsub!('@', 'at_sign_at') unless presenter.depositor.blank? %>
        # <% presenter.depositor.gsub!('TOMBSTONE-', '') unless presenter.depositor.blank? %>
        # <%= raw (presenter.attribute_to_html(:depositor)).gsub('at_sign_at', '@') %>
        rv = value.gsub('@', 'at_sign_at')
        rv.gsub!('TOMBSTONE-', '')
        rv = super(rv)
        rv.gsub!('at_sign_at', '@')
        return rv
      end

    end

  end
end
