require 'rails_helper'

RSpec.describe Hyrax::DashboardController, type: :controller, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  context "with an unauthenticated user" do
    it "redirects to sign-in page" do
      get :show
      expect(response).to be_redirect
      expect(flash[:alert]).to eq("You need to sign in or sign up before continuing.")
    end
  end

  context "with an authenticated user" do
    let(:user) { factory_bot_create_user(:user) }

    before do
      sign_in user
    end

    it "renders the dashboard with the user's info" do
      get :show
      expect(response).to be_successful
      expect(assigns(:presenter)).to be_instance_of Hyrax::Dashboard::UserPresenter
      expect(response).to render_template('show_user')
    end
  end

  context 'with an admin user' do
    let(:service) { instance_double(Hyrax::AdminSetService, search_results_with_work_count: results) }
    let(:results) { instance_double(Array) }
    let(:user) { factory_bot_create_user(:admin) }

    before do
      sign_in user
      allow(Hyrax::AdminSetService).to receive(:new).and_return(service)
    end

    it "is successful" do
      get :show
      expect(response).to be_successful
      expect(assigns[:admin_set_rows]).to eq results
      expect(response).to render_template('show_admin')
    end
  end
end
