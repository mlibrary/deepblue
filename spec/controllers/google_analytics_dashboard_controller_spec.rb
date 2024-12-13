require 'rails_helper'

RSpec.describe GoogleAnalyticsDashboardController do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  describe 'class variables' do
    it { expect( described_class.presenter_class ).to eq GoogleAnalyticsDashboardPresenter }
  end

  let(:themed_layout) { 'dashboard' }
  let(:admin)     { factory_bot_create_user(:admin) }
  let(:user)      { factory_bot_create_user(:user) }
  let(:access_denied) { I18n.t!(:"unauthorized.default", default: 'You are not authorized to access this page.') }

  describe "#show" do
    before do
      #expect(described_class).to receive(:with_themed_layout).with(themed_layout).and_call_original
    end
    context "admin" do
      before do
        sign_in admin
      end
      it "is successful get" do
        get :show, params: {}
        expect(response).to be_successful
      end
      it "is successful put" do
        put :show, params: {}
        expect(response).to be_successful
      end
    end

    context "user" do
      before do
        sign_in user
      end
      it "is successful get" do
        get :show, params: {}
        expect(response).to be_successful
      end
      it "is successful put" do
        put :show, params: {}
        expect(response).to be_successful
      end
      # it "is unauthorized get" do
      #   get :show, params: {}
      #   expect(response).to redirect_to(root_path)
      #   expect(flash[:alert]).to eq access_denied
      # end
      # it "is unauthorized put" do
      #   put :show, params: {}
      #   expect(response).to redirect_to(root_path)
      #   expect(flash[:alert]).to eq access_denied
      # end
    end
  end

end
