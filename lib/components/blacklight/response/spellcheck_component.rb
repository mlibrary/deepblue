# frozen_string_literal: true
# Added: hyrax4
# monkey - copied up from blacklight gem because the blacklight helpers were not being found

module Blacklight
  module Response
    # Render spellcheck results for a search query
    class SpellcheckComponent < ViewComponent::Base
      # @param [Blacklight::Response] response
      # @param [Array<String>] options explicit spellcheck options to render
      def initialize(response:, options: nil)
        @response = response
        @options = options
        @options ||= options_from_response(@response)
      end

      def link_to_query(query)
        begin # Deprecation.silence(Blacklight::UrlHelperBehavior) do
          helpers.link_to_query(query)
        end
      end

      def render?
        begin # Deprecation.silence(Blacklight::BlacklightHelperBehavior) do
          @options&.any? && helpers.should_show_spellcheck_suggestions?(@response)
        end
      end

      private

      def options_from_response(response)
        if response&.spelling&.collation
          [response.spelling.collation]
        elsif response&.spelling&.words
          response.spelling.words
        end
      end
    end
  end
end
