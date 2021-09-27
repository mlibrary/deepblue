require 'rails_helper'

RSpec.describe Hyrax::AnonymousLinksController, type: :controller, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:debug_verbose) { false }

  let(:user) { create(:user) }
  let(:file) { create(:file_set, user: user) }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.anonymous_links_controller_debug_verbose ).to eq( debug_verbose )
    end
  end

  describe '#show_presenter' do
    RSpec.shared_examples 'shared show_presenter' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.anonymous_links_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.anonymous_links_controller_debug_verbose = debug_verbose
      end

      its(:show_presenter) do
        is_expected.to eq(Hyrax::AnonymousLinkPresenter)
      end
    end
    it_behaves_like 'shared show_presenter', false
    # it_behaves_like 'shared show_presenter', true # no debug statements to trigger
  end

  describe 'logged in user with edit permission', skip: false do
    RSpec.shared_examples 'shared logged in user with edit permission' do |dbg_verbose|
      before do
        described_class.anonymous_links_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.anonymous_links_controller_debug_verbose = debug_verbose
      end
      context do
        let(:hash) { "some-dummy-sha2-hash" }

        before { sign_in user }

        context "POST create" do
          before do
            expect(Digest::SHA2).to receive(:new).and_return(hash)
          end

          describe "creating a anonymous download link" do
            it "returns a link for downloading" do
              post 'create_anonymous_download', params: { id: file }
              expect(response).to be_success
              expect(response.body).to eq main_app.download_anonymous_link_url(hash, host: request.host, locale: 'en')
            end
          end

          describe "creating a anonymous show link", skip: false do
            it "returns a link for showing" do
              post 'create_anonymous_show', params: { id: file }
              expect(response).to be_success
              expect(response.body).to eq main_app.show_anonymous_link_url(hash, host: request.host, locale: 'en')
            end
          end
        end

        # TODO: fix
        context "GET index", skip: false do
          describe "viewing existing links" do
            before { get :index, params: { id: file } }
            subject { response }

            it { is_expected.to be_success }
          end
        end

        # TODO: fix
        context "DELETE destroy", skip: true do
          let!(:link) { create(:download_link) }

          it "deletes the link" do
            expect { delete :destroy, params: { id: file, link_id: link } }.to change { AnonymousLink.count }.by(-1)
            expect(response).to be_success
          end
        end
      end
    end
    it_behaves_like 'shared logged in user with edit permission', false
    it_behaves_like 'shared logged in user with edit permission', true
  end

  describe 'logged in user without edit permission' do
    RSpec.shared_examples 'shared logged in user without edit permission' do |dbg_verbose|
      before do
        described_class.anonymous_links_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.anonymous_links_controller_debug_verbose = debug_verbose
      end
      context do
        let(:other_user) { create(:user) }
        let(:file) { create(:file_set, user: user, read_users: [other_user]) }

        before do
          sign_in other_user
        end

        subject { response }

        describe 'creating a anonymous download link' do
          before { post 'create_anonymous_download', params: { id: file } }
          it 'fails' do
            is_expected.not_to be_success
            expect(response).to redirect_to(root_path)
            expect(flash[:alert]).to eq I18n.t('hyrax.anonymous_links.alert.insufficient_privileges')
          end
        end

        describe 'creating a anonymous show link' do
          before { post 'create_anonymous_show', params: { id: file } }
          it 'fails' do
            is_expected.not_to be_success
            expect(response).to redirect_to(root_path)
            expect(flash[:alert]).to eq I18n.t('hyrax.anonymous_links.alert.insufficient_privileges')
          end
        end

        describe 'viewing existing links' do
          before { get :index, params: { id: file } }
          it 'fails' do
            is_expected.not_to be_success
            expect(response).to redirect_to(root_path)
            expect(flash[:alert]).to eq I18n.t('hyrax.anonymous_links.alert.insufficient_privileges')
          end
        end
      end
    end
    it_behaves_like 'shared logged in user without edit permission', false
    it_behaves_like 'shared logged in user without edit permission', true
  end

  describe 'unknown user' do
    RSpec.shared_examples 'it requires login' do
      let(:flash_msg) { "You need to sign in or sign up before continuing." }
      # let(:flash_msg) { I18n.t('devise.failure.unauthenticated') }
      # let(:flash_msg) { I18n.t(:"unauthorized.default", default: 'You are not authorized to access this page.') }
      it 'requires login' do
        expect(response).to_not be_nil
        # expect(response).to fail_redirect_and_flash(main_app.new_user_session_path, flash_msg)
        expect(response.status).to eq 302
        expect(response).to redirect_to(main_app.new_user_session_path)
        expect(flash[:alert]).to eq flash_msg
      end
    end
    RSpec.shared_examples 'shared unknown user' do |dbg_verbose|
      before do
        described_class.anonymous_links_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.anonymous_links_controller_debug_verbose = debug_verbose
      end
      context do
        subject { response }

        describe "creating a anonymous download link" do
          before { post 'create_anonymous_download', params: { id: file } }
          it_behaves_like 'it requires login'
        end

        describe "creating a anonymous show link" do
          before { post 'create_anonymous_show', params: { id: file } }
          it_behaves_like 'it requires login'
        end

        describe "viewing existing links" do
          before { get :index, params: { id: file } }
          it_behaves_like 'it requires login'
        end
      end
    end
    it_behaves_like 'shared unknown user', false
    # it_behaves_like 'shared unknown user', true # no debug statements to trigger
  end

end
