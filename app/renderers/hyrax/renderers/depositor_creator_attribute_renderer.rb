# frozen_string_literal: true

module Hyrax
  module Renderers

    # This is used by PresentsAttributes to show a doi
    #   e.g.: presenter.attribute_to_html(:doi, render_as: :doi)
    class DepositorCreatorAttributeRenderer < AttributeRenderer

      mattr_accessor :depositor_creator_attribute_renderer_debug_verbose, default: false

      ##
      # Special treatment for doi.
      def attribute_value_to_html(value)
        debug_verbose = depositor_creator_attribute_renderer_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value=#{value}",
                                               "" ] if debug_verbose
        unless debug_verbose
          return "false" if value.blank?
          return "true" if "true" == value
          return "true" if "1" == value
          return "false"
        end
        return "false (orignal value is blank)" if value.blank?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value not blank",
                                               "" ] if debug_verbose
        return "true (original value is \"true\")" if "true" == value
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value not equal to string true",
                                               "" ] if debug_verbose
        return "true (original value is \"1\")" if "1" == value
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "value not equal to string 1",
                                               "" ] if debug_verbose
        return "false  (original value is \"#{value}\")"
      end

    end

  end
end
