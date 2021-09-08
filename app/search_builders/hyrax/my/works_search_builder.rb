module Hyrax
  # Added to allow for the Hyrax::My::WorksController to show only things I have deposited
  # If the work went through mediated deposit, I may no longer have edit access to it.
  class My::WorksSearchBuilder < My::SearchBuilder

    mattr_accessor :hyrax_my_search_builder_debug_verbose, default: false

    include Hyrax::FilterByType

    # We remove the access controls filter, because some of the works a user has
    # deposited may have gone through a workflow which has removed their ability
    # to edit the work.
  
    # So that mediated works could show up on the My Works tab
    # self.default_processor_chain -= [:add_access_controls_to_solr_params]
    # We remove the active works filter, so a depositor can see submitted works in any state.
    self.default_processor_chain -= [:only_active_works, :add_access_controls_to_solr_params]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "self.class.name=#{self.class.name}",
                                           "about to add to default processor chain",
                                           "self.default_processor_chain=#{self.default_processor_chain}",
                                           "" ] if hyrax_my_search_builder_debug_verbose
    self.default_processor_chain += [:remove_draft_works]

    def only_works?
      true
    end

  end
end
