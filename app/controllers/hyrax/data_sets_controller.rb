# Generated via
#  `rails generate hyrax:work DataSet`
module Hyrax
  # Generated controller for DataSet
  class DataSetsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::DataSet

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::DataSetPresenter
  end
end
