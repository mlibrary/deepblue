# frozen_string_literal: true
# Added: hyrax4
# monkey - copied up from blacklight gem because the blacklight helpers were not being found

module Blacklight
  module Response
    # Render spellcheck results for a search query
    class ViewTypeComponent < ViewComponent::Base
      renders_many :views, 'Blacklight::Response::ViewTypeButtonComponent'

      # @param [Blacklight::Response] response
      def initialize(response:, views: {}, search_state:, selected: nil)
        @response = response
        @views = views
        @search_state = search_state
        @selected = selected
      end

      def before_render
        return if views.any?

        @views.each do |key, config|
          with_view(key: key, view: config, selected: @selected == key, search_state: @search_state)
        end
      end

      def render?
        begin # Deprecation.silence(Blacklight::ConfigurationHelperBehavior) do
          helpers.has_alternative_views?
        end
      end
    end
  end
end
