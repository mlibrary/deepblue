require 'rails_helper'

RSpec.describe Hyrax::SingleUseLinksController, type: :controller do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:user) { create(:user) }
  let(:file) { create(:file_set, user: user) }

  describe "::show_presenter" do
    subject { described_class }

    its(:show_presenter) { is_expected.to eq(Hyrax::SingleUseLinkPresenter) }
  end

  describe "logged in user with edit permission" do
    let(:hash) { "some-dummy-sha2-hash" }

    before { sign_in user }

    context "POST create" do
      before do
        expect(Digest::SHA2).to receive(:new).and_return(hash)
      end

      describe "creating a single-use download link" do
        it "returns a link for downloading" do
          post 'create_download', params: { id: file }
          expect(response).to be_success
          expect(response.body).to eq Hyrax::Engine.routes.url_helpers.download_single_use_link_url(hash, host: request.host, locale: 'en')
        end
      end

      describe "creating a single-use show link" do
        it "returns a link for showing" do
          post 'create_show', params: { id: file }
          expect(response).to be_success
          expect(response.body).to eq Hyrax::Engine.routes.url_helpers.show_single_use_link_url(hash, host: request.host, locale: 'en')
        end
      end
    end

    # TODO: fix
    context "GET index", skip: true do
      describe "viewing existing links" do
        before { get :index, params: { id: file } }
        subject { response }

        it { is_expected.to be_success }
      end
    end

    context "DELETE destroy" do
      let!(:link) { create(:download_link) }

      it "deletes the link" do
        expect { delete :destroy, params: { id: file, link_id: link } }.to change { SingleUseLink.count }.by(-1)
        expect(response).to be_success
      end
    end
  end

  describe "logged in user without edit permission" do
    let(:other_user) { create(:user) }
    let(:file) { create(:file_set, user: user, read_users: [other_user]) }

    before { sign_in other_user }
    subject { response }

    describe "creating a single-use download link" do
      before { post 'create_download', params: { id: file } }
      it { is_expected.not_to be_success }
    end

    describe "creating a single-use show link" do
      before { post 'create_show', params: { id: file } }
      it { is_expected.not_to be_success }
    end

    describe "viewing existing links" do
      before { get :index, params: { id: file } }
      it { is_expected.not_to be_success }
    end
  end

  describe "unknown user" do
    subject { response }

    describe "creating a single-use download link" do
      before { post 'create_download', params: { id: file } }
      it { is_expected.not_to be_success }
    end

    describe "creating a single-use show link" do
      before { post 'create_show', params: { id: file } }
      it { is_expected.not_to be_success }
    end

    describe "viewing existing links" do
      before { get :index, params: { id: file } }
      it { is_expected.not_to be_success }
    end

  end

end
