require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe Hyrax::Admin::WorkflowsController, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  describe "#index" do
    before do
      expect(controller).to receive(:authorize!).with(:review, :submissions).and_return(true)
    end
    it "is successful" do
      expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
      expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
      expect(controller).to receive(:add_breadcrumb).with('Tasks', '#')
      expect(controller).to receive(:add_breadcrumb).with('Review Submissions', "/admin/workflows")

      get :index
      expect(response).to be_successful
      expect(assigns[:status_list]).to be_kind_of Hyrax::Workflow::StatusListService
      expect(assigns[:published_list]).to be_kind_of Hyrax::Workflow::StatusListService
    end
  end

end
