# frozen_string_literal: true

module Hyrax

  # Generated controller
  class SamplesController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Sample

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::SamplesPresenter
  end

end
