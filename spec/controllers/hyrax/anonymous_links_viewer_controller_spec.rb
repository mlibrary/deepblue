require 'rails_helper'

RSpec.describe Hyrax::AnonymousLinksViewerController, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  # routes { Hyrax::Engine.routes }

  let(:user) { build(:user) }
  let(:file) do
    create(:file_set, label: 'world.png', user: user)
  end

  describe "retrieval links", skip: false do
    let :show_link do
      AnonymousLink.create itemId: file.id,
                           path: Rails.application.routes.url_helpers.hyrax_file_set_path(id: file, locale: 'en')
    end

    let :download_link do
      Hydra::Works::AddFileToFileSet.call_enhanced_version( file, File.open(fixture_path + '/world.png'), :original_file )
      AnonymousLink.create itemId: file.id, path: Hyrax::Engine.routes.url_helpers.download_path(id: file, locale: 'en')
    end

    let(:show_link_hash) { show_link.downloadKey }
    let(:download_link_hash) { download_link.downloadKey }

    describe "GET 'download'" do
      let(:expected_content) { ActiveFedora::Base.find(file.id).original_file.content }

      it "downloads the file and deletes the link from the database" do
        expect(controller).to receive(:send_file_headers!).with( filename: 'world.png',
                                                                 disposition: 'attachment',
                                                                 type: 'image/png')
        get :download, params: { id: download_link_hash }
        expect(response.body).to eq expected_content
        expect(response).to be_success
        # expect { AnonymousLink.find_by_downloadKey!(download_link_hash) }.to raise_error ActiveRecord::RecordNotFound
      end

      context "when the key is not found" do
        before { AnonymousLink.find_by_downloadKey!(download_link_hash).destroy }

        it "shows the main page with message" do
          get :download, params: { id: download_link_hash }
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include(I18n.t('hyrax.anonymous_links.expired_html'))
        end
      end
    end

    describe "GET 'show'" do

      it "renders the file set's show page and deletes the link from the database" do
        get 'show', params: { id: show_link_hash }
        expect(response).to redirect_to( "http://test.host/concern/file_sets/#{file.id}/anonymous_link/#{show_link_hash}" )
        expect(flash[:notice]).to include(I18n.t('hyrax.anonymous_links.notice.show_file_html'))
        # expect(assigns[:presenter].id).to eq file.id
        # expect { AnonymousLink.find_by_downloadKey!(show_link_hash) }.to raise_error ActiveRecord::RecordNotFound
      end

      context "shows the main page with message when the key is not found" do
        before { AnonymousLink.find_by_downloadKey!(show_link_hash).destroy }
        it "redirects to the main page" do
          get :show, params: { id: show_link_hash }
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include(I18n.t('hyrax.anonymous_links.expired_html'))
        end
      end

      it "shows the main page with message when get show path with download hash" do
        get :show, params: { id: download_link_hash }
        expect(response).to redirect_to( "http://test.host/concern/file_sets/#{file.id}/anonymous_link/#{download_link_hash}" )
        expect(flash[:notice]).to include(I18n.t('hyrax.anonymous_links.notice.show_file_html'))
      end
    end

  end

end
