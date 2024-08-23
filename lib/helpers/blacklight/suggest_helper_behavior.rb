# frozen_string_literal: true
# Added: hyrax4
# monkey - copied up from blacklight gem because the blacklight helpers were not being found

module Blacklight
  module SuggestHelperBehavior
    ##
    # @   deprecated
    # @return [Boolean] should autocomplete be enabled in the UI
    def autocomplete_enabled?
      blacklight_config.autocomplete_enabled.present? &&
        blacklight_config.autocomplete_path.present?
    end
    # deprecation_deprecate autocomplete_enabled?: "use SearchBarPresenter#autocomplete_enabled?"
  end
end
