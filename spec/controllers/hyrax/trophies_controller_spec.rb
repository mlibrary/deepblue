require 'rails_helper'

RSpec.describe Hyrax::TrophiesController, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  describe "#toggle_trophy" do
    let(:user) { factory_bot_create_user(:user) }
    let(:work) { create(:work, user: user) }

    context "for a work we have edit access on" do
      before do
        sign_in user
      end
      it "creates a trophy for a work" do
        post :toggle_trophy, params: { id: work.id }
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq user.id
        expect(json['work_id']).to eq work.id
      end
      context 'where the trophy already exists' do
        before do
          user.trophies.create(work_id: work.id)
        end
        it 'destroys the trophy' do
          expect { post :toggle_trophy, params: { id: work.id } }
            .to change { Trophy.count }.by(-1)

          expect(response).to be_successful
          json = JSON.parse(response.body)
          expect(json['user_id']).to eq user.id
          expect(json['work_id']).to eq work.id
        end
      end
    end

    context "for a work that we don't have edit access on" do
      it "does not create a trophy" do
        post :toggle_trophy, params: { id: work.id }
        expect(response).not_to be_successful
      end
    end
  end
end
