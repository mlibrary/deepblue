# frozen_string_literal: true
# Reviewed: hyrax4

# monkey override

# Added to allow for the My controller to show only things I have edit access to
class Hyrax::HomepageSearchBuilder < Hyrax::SearchBuilder

  mattr_accessor :hyrax_homepage_search_builder_debug_verbose, default: false

  include Hyrax::FilterByType
  self.default_processor_chain += [:add_access_controls_to_solr_params]
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "self.class.name=#{self.class.name}",
                                         "about to add to default processor chain",
                                         "self.default_processor_chain=#{self.default_processor_chain}",
                                         "" ] if hyrax_homepage_search_builder_debug_verbose
  # self.default_processor_chain += [:remove_draft_works]

  def only_works?
    true
  end

end
