# frozen_string_literal: true
# Reviewed: hyrax4

# monkey patch

module Hyrax
  class PresenterRenderer

    # begin monkey
    mattr_accessor :presenter_renderer_debug_verbose, default: false
    # end monkey

    include ActionView::Helpers::TranslationHelper

    def initialize(presenter, view_context)
      @presenter = presenter
      @view_context = view_context
    end

    ##
    # Renders a collection field partial
    #
    # @return [ActiveSupport::SafeBuffer] an html safe string containing the value markup
    def value(field_name, locals = {})
      # begin monkey
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "field_name=#{field_name}",
                                             "" ] if presenter_renderer_debug_verbose
      # end monkey
      render_show_field_partial(field_name, locals)
    end

    def label(field)
      t(:"#{model_name.param_key}.#{field}",
        scope: label_scope,
        default: [:"defaults.#{field}", field.to_s.humanize]).presence
    end

    ##
    # monkey # (at)deprecated
    def fields(terms, &_block)
      Deprecation.warn("Fields is deprecated for removal in Hyrax 4.0.0. use #value and #label directly instead.")
      @view_context.safe_join(terms.map { |term| yield self, term })
    end

    private

      def render_show_field_partial(field_name, locals)
        partial = find_field_partial(field_name)
        @view_context.render partial, locals.merge(key: field_name, record: @presenter)
      end

      def find_field_partial(field_name)
        ["#{collection_path}/show_fields/_#{field_name}", "records/show_fields/_#{field_name}",
         "#{collection_path}/show_fields/_default", "records/show_fields/_default"].find do |partial|
          # begin monkey
          Rails.logger.debug "Looking for show field partial #{partial}" if presenter_renderer_debug_verbose
          # end monkey
          return partial.sub(/\/_/, '/') if partial_exists?(partial)
        end
      end

      def collection_path
        @collection_path ||= ActiveSupport::Inflector.tableize(model_name)
      end

      def partial_exists?(partial)
        @view_context.lookup_context.find_all(partial).any?
      end

      def label_scope
        :"simple_form.labels"
      end

      def model_name
        @presenter.model_name
      end
  end
end
