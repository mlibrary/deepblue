# frozen_string_literal: true

module Hyrax

  # Generated controller
  class SampleTwosController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::SampleThree

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::SampleThreesPresenter

    public # place public methods here
    def create
      super
    end

    def show
      super
    end

    private # place private methods here
    def local_method

    end

    public

  end

end
