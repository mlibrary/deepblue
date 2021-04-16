# frozen_string_literal: true

module Hyrax

  # Generated controller
  class SampleTwosController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::SampleTwo

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::SampleTwosPresenter

    public
    def create
      super.tap { |param| puts param }
    end

    def show
      super
    end

  end

end
