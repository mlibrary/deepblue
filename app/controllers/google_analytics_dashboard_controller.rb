# frozen_string_literal: true

class GoogleAnalyticsDashboardController < ApplicationController

  include ActiveSupport::Concern
  include Blacklight::Base
  include Blacklight::AccessControls::Catalog
  include Hyrax::Breadcrumbs
  with_themed_layout 'dashboard'
  before_action :authenticate_user!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class
  self.presenter_class = GoogleAnalyticsDashboardPresenter

  def show
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'hyrax/dashboard/show_google_analytics_dashboard'
  end

end
