# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::SingleUseLinksViewerController do

  include Devise::Test::ControllerHelpers
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  routes { Hyrax::Engine.routes }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.single_use_links_viewer_controller_debug_verbose ).to eq( debug_verbose )
    end
  end

  describe "retrieval links" do
    let(:user) { build(:user) }
    let(:file) do
      create(:file_set, label: 'world.png', user: user)
    end

    RSpec.shared_examples 'shared retrieval links' do |dbg_verbose|
      before do
        described_class.single_use_links_viewer_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
        # ::Deepblue::LoggingHelper.echo_to_puts = true if !debug_verbose
      end
      after do
        described_class.single_use_links_viewer_controller_debug_verbose = debug_verbose
        # ::Deepblue::LoggingHelper.echo_to_puts = false if !debug_verbose
      end
      context do

        let :show_link do
          SingleUseLink.create item_id: file.id,
                               path: Rails.application.routes.url_helpers.hyrax_file_set_path(id: file, locale: 'en')
        end

        let :download_link do
          Hydra::Works::AddFileToFileSet.call_enhanced_version( file, File.open(fixture_path + '/world.png'), :original_file )
          SingleUseLink.create item_id: file.id, path: Hyrax::Engine.routes.url_helpers.download_path(id: file, locale: 'en')
        end

        let(:show_link_hash) { show_link.download_key }
        let(:download_link_hash) { download_link.download_key }

        describe "GET 'download'", skip: false do
          let(:expected_content) { Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: file.id, use_valkyrie: false).original_file.content }
          it "downloads the file and deletes the link from the database", skip: false do
            expect(controller).to receive(:send_file_headers!).with({ filename: 'world.png', disposition: 'attachment', type: 'image/png' })
            get :download, params: { id: download_link_hash }
            expect(response.body).to eq expected_content
            expect(response).to be_successful
            expect { SingleUseLink.find_by_download_key!(download_link_hash) }.to raise_error ActiveRecord::RecordNotFound
          end

          context "when the key is not found", skip: false do
            before { SingleUseLink.find_by_download_key!(download_link_hash).destroy }

            it "shows the main page with message" do
              get :download, params: { id: download_link_hash }
              expect(response).to redirect_to(root_path)
              expect(flash[:alert]).to include(I18n.t('hyrax.single_use_links.expired_html'))
            end
          end
        end

        describe "GET 'show'", skip: false do

          it "renders the file set's show page and deletes the link from the database" do
            get 'show', params: { id: show_link_hash }
            expect(response).to redirect_to( "http://test.host/concern/file_sets/#{file.id}/single_use_link/#{show_link_hash}" )
            expect(flash[:notice]).to include(I18n.t('hyrax.single_use_links.notice.show_file_html'))
            # expect(assigns[:presenter].id).to eq file.id
            # expect { SingleUseLink.find_by_download_key!(show_link_hash) }.to raise_error ActiveRecord::RecordNotFound
          end

          context "when the key is not found" do
            before { SingleUseLink.find_by_download_key!(show_link_hash).destroy }
            it "redirects to the main page" do
              get :show, params: { id: show_link_hash }
              expect(response).to redirect_to(root_path)
              expect(flash[:alert]).to include(I18n.t('hyrax.single_use_links.expired_html'))
            end
          end

          it "shows the main page with message when get show path with download hash" do
            get :show, params: { id: download_link_hash }
            expect(response).to redirect_to( "http://test.host/concern/file_sets/#{file.id}/single_use_link/#{download_link_hash}" )
            expect(flash[:notice]).to include(I18n.t('hyrax.single_use_links.notice.show_file_html'))
          end

          it "returns 404 on attempt to get show path with download hash", skip: Rails.configuration.hyrax4_spec_skip do
            get :show, params: { id: download_link_hash }
            expect(response).to render_template("hyrax/single_use_links_viewer/single_use_error", "layouts/error")
          end

        end
      end
    end
    it_behaves_like 'shared retrieval links', false
    it_behaves_like 'shared retrieval links', true

  end

end
