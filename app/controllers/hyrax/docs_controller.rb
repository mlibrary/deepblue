# Generated via
#  `rails generate hyrax:work Doc`
module Hyrax
  # Generated controller for Doc
  class DocsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    #Dissertations had it off
    #include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Doc

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::DocPresenter
  end
end
