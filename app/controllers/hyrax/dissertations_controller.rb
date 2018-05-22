# frozen_string_literal: true

module Hyrax
  # Generated controller for Dissertation
  class DissertationsController < DeepblueController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    #include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Dissertation

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::DissertationPresenter
  end
end
