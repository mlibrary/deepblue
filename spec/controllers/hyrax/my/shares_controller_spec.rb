# frozen_string_literal: true

require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe Hyrax::My::SharesController, type: :controller, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  describe "logged in user" do
    let(:user) { factory_bot_create_user(:user) }

    before do
      sign_in user
    end

    describe "#index" do
      let(:other_user)   { factory_bot_create_user(:user) }
      let(:someone_else) { factory_bot_create_user(:user) }

      let!(:my_work)                  { create(:work, user: user) }
      let!(:unshared_work)            { create(:work, user: other_user) }
      let!(:shared_with_me)           { create(:work, user: other_user, edit_users: [user, other_user]) }
      let!(:read_shared_with_me)      { create(:work, user: other_user, read_users: [user, other_user]) }
      let!(:shared_with_someone_else) { create(:work, user: other_user, edit_users: [someone_else, other_user]) }
      let!(:my_collection)            { create(:public_collection_lw, user: user) }

      it "responds with success" do
        get :index
        expect(response).to be_successful
      end

      context "with multiple pages of results" do
        before { 2.times { create(:work, user: other_user, edit_users: [user, other_user]) } }
        it "paginates" do
          get :index, params: { per_page: 2 }
          expect(assigns[:document_list].length).to eq 2
          get :index, params: { per_page: 2, page: 2 }
          expect(assigns[:document_list].length).to be >= 1
        end
      end

      it "shows only documents that are shared with me via edit access" do
        get :index
        expect(assigns[:document_list].map(&:id)).to contain_exactly(shared_with_me.id)
      end
    end
  end

  describe "#search_facet_path" do
    subject { controller.send(:search_facet_path, id: 'keyword_sim') }

    it { is_expected.to eq "/dashboard/shares/facet/keyword_sim?locale=en" }
  end
end
