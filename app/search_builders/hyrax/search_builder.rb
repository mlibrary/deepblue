# frozen_string_literal: true
# Reviewed: hyrax4

# monkey override

module Hyrax
  class SearchBuilder < ::SearchBuilder

    mattr_accessor :hyrax_search_builder_debug_verbose, default: false

    def initialize(*options)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if hyrax_search_builder_debug_verbose
      super
    end

  end
end
