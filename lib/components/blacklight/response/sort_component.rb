# frozen_string_literal: true
# Added: hyrax4
# monkey - copied up from blacklight gem because the blacklight helpers were not being found

module Blacklight
  module Response
    class SortComponent < ViewComponent::Base
      def initialize(param: 'sort', choices: {}, search_state:, id: 'sort-dropdown', classes: [], selected: nil)
        @param = param
        @choices = choices
        @search_state = search_state
        @id = id
        @classes = classes
        @selected = selected
      end
    end
  end
end
