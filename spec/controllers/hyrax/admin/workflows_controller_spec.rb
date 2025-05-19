# frozen_string_literal: true
require 'rails_helper'

include Warden::Test::Helpers

RSpec.describe Hyrax::Admin::WorkflowsController, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  describe "#index" do
    let(:user) { factory_bot_create_user(:admin) }

    before do
      sign_in user
      expect(controller).to receive(:authorize!).with(:review, :submissions).and_return(true)
    end

    it "is successful" do
      expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
      expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
      expect(controller).to receive(:add_breadcrumb).with('Tasks', '#')
      expect(controller).to receive(:add_breadcrumb).with('Review Submissions', "/admin/workflows")

      get :index
      expect(response).to be_successful
      # Hyrax5 update: expect(assigns[:status_list]).to respond_to(:each)
      # Hyrax5 update: expect(assigns[:published_list]).to respond_to(:each)
    end
  end

end
