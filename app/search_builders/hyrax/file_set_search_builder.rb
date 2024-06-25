# frozen_string_literal: true
# Reviewed: hyrax4

# monkey override

module Hyrax

  # Our parent class is the generated SearchBuilder descending from Blacklight::SearchBuilder
  # It includes Blacklight::Solr::SearchBuilderBehavior, Hydra::AccessControlsEnforcement, Hyrax::SearchFilters
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/search_builder.rb Blacklight::SearchBuilder parent
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr/search_builder_behavior.rb Blacklight::Solr::SearchBuilderBehavior
  # @see https://github.com/samvera/hyrax/blob/master/app/search_builders/hyrax/README.md SearchBuilders README
  # @note the default_processor_chain defined by Blacklight::Solr::SearchBuilderBehavior provides many possible points of override
  class FileSetSearchBuilder < ::SearchBuilder

    mattr_accessor :file_set_search_builder_debug_verbose, default: false

    include SingleResult

    def initialize(*options)
      # Really big output!
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "options=#{options}",
      #                                        "" ] if file_set_search_builder_debug_verbose
      super(*options)
      # Really big output!
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "options=#{options}",
      #                                        "" ] if file_set_search_builder_debug_verbose
    end

    # This overrides the models in FilterByType
    def models
      [::FileSet]
    end

  end

end
