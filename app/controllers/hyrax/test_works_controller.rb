# Generated via
#  `rails generate hyrax:work TestWork`
module Hyrax
  # Generated controller for TestWork
  class TestWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::TestWork

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::TestWorkPresenter
  end
end
