# frozen_string_literal: true

# monkey override

module Hyrax
  # Returns all works, either active or suppressed.
  # This should only be used by an admin user
  class WorksSearchBuilder < Hyrax::SearchBuilder

    mattr_accessor :hyrax_search_builder_debug_verbose, default: false

    include Hyrax::FilterByType
    self.default_processor_chain -= [:only_active_works]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "self.class.name=#{self.class.name}",
                                           "about to add to default processor chain",
                                           "self.default_processor_chain=#{self.default_processor_chain}",
                                           "" ] if hyrax_search_builder_debug_verbose
    # self.default_processor_chain += [:remove_draft_works]

    def only_works?
      true
    end

  end
end
