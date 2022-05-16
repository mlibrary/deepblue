require 'rails_helper'

RSpec.describe Hyrax::DownloadsController, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  describe '#show' do
    let(:user) { create(:user) }
    let(:file_set) do
      create(:file_with_work, user: user, content: File.open(fixture_path + '/image.png'))
    end
    let(:work) { file_set.parent }
    let(:default_image) { ActionController::Base.helpers.image_path 'default.png' }

    it 'raises an error if the object does not exist' do
      expect do
        get :show, params: { id: '8675309' }
      end.to raise_error Blacklight::Exceptions::InvalidSolrID
    end

    context "when user doesn't have access", skip: true do
      let(:another_user) { create(:user) }

      before { sign_in another_user }

      it 'returns :unauthorized status with image content' do
        get :show, params: { id: file_set.to_param }
        expect(response).to have_http_status(:unauthorized)
        expect(response).not_to redirect_to default_image
        expect(response.content_type).to eq 'image/png'
      end
    end

    context "when user isn't logged in", skip: true do
      context "and the unauthorized image exists" do
        before do
          allow(File).to receive(:exist?).and_return(true)
        end

        it 'returns :unauthorized status with image content' do
          get :show, params: { id: file_set.to_param }
          expect(response).to have_http_status(:unauthorized)
          expect(response).not_to redirect_to default_image
          expect(response.content_type).to eq 'image/png'
        end
      end

      context "and the unauthorized image doesn't exist" do
        before do
          allow(File).to receive(:exist?).and_return(false)
        end

        it 'redirects to the default image' do
          get :show, params: { id: file_set.to_param }
          expect(response).to redirect_to default_image
        end
      end

      it 'authorizes the resource using only the id' do
        expect(controller).to receive(:authorize!).with(:download, file_set.id)
        get :show, params: { id: file_set.to_param }
      end
    end

    context "when the user has access" do
      before { sign_in user }

      it 'sends the original file' do
        expect(work).to_not eq nil
        expect(controller).to receive(:report_irus_analytics_request).and_call_original
        expect(::Deepblue::IrusHelper).to receive(:log) do |args|
          expect( args[:event] ).to eq "analytics_request"
        end
        expect(controller).to receive(:show_html).at_least(:once).and_call_original
        expect(controller).to receive(:is_thumbnail_request?).at_least(:once).and_call_original
        expect(controller).to receive(:download_skip_send_irus_analytics?).and_return false
        expect(PersistHelper).to receive(:find).with(file_set.id).and_return file_set
        expect(file_set.parent).to eq work
        # expect(file_set.parent).to receive(:workflow_state).at_least(:once).and_return 'deposited'
        expect(controller).to receive(:send_irus_analytics_request)
        get :show, params: { id: file_set.id }
        expect(response.body).to eq file_set.original_file.content
      end

      context "with an alternative file" do
        context "that is persisted" do
          let(:file) { File.open(fixture_path + '/world.png', 'rb') }
          let(:content) { file.read }

          before do
            allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).and_return(fixture_path + '/world.png')
            expect(controller).to receive(:report_irus_analytics_request).and_call_original
            # expect(::Deepblue::IrusHelper).to receive(:log) do |args|
            #   expect( args[:event] ).to eq "analytics_request"
            # end
            expect(controller).to receive(:show_html).at_least(:once).and_call_original
            expect(controller).to_not receive(:download_skip_send_irus_analytics?)
            expect(controller).to_not receive(:skip_send_irus_analytics?)
            expect(controller).to_not receive(:send_irus_analytics_request)
          end

          it 'sends requested file content' do
            get :show, params: { id: file_set, file: 'thumbnail' }
            expect(response).to be_successful
            expect(response.body).to eq content
            expect(response.headers['Content-Length']).to eq "4218"
            expect(response.headers['Accept-Ranges']).to eq "bytes"
          end

          it 'retrieves the thumbnail without contacting Fedora' do
            expect(ActiveFedora::Base).not_to receive(:find).with(file_set.id)
            get :show, params: { id: file_set, file: 'thumbnail' }
          end

          context "stream" do
            it "head request" do
              request.env["HTTP_RANGE"] = 'bytes=0-15'
              head :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers['Content-Length']).to eq '4218'
              expect(response.headers['Accept-Ranges']).to eq 'bytes'
              expect(response.headers['Content-Type']).to start_with 'image/png'
            end

            it "sends the whole thing" do
              request.env["HTTP_RANGE"] = 'bytes=0-4217'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 0-4217/4218'
              expect(response.headers["Content-Length"]).to eq '4218'
              expect(response.headers['Accept-Ranges']).to eq 'bytes'
              expect(response.headers['Content-Type']).to start_with "image/png"
              expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"world.png\""
              expect(response.body).to eq content
              expect(response.status).to eq 206
            end

            it "sends the whole thing when the range is open ended" do
              request.env["HTTP_RANGE"] = 'bytes=0-'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.body).to eq content
            end

            it "gets a range not starting at the beginning" do
              request.env["HTTP_RANGE"] = 'bytes=4200-4217'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 4200-4217/4218'
              expect(response.headers["Content-Length"]).to eq '18'
            end

            it "gets a range not ending at the end" do
              request.env["HTTP_RANGE"] = 'bytes=4-11'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 4-11/4218'
              expect(response.headers["Content-Length"]).to eq '8'
            end
          end
        end

        context "that isn't persisted", skip: true do
          it "raises an error if the requested file does not exist" do
            expect do
              get :show, params: { id: file_set, file: 'thumbnail' }
            end.to raise_error Hyrax::ObjectNotFoundError
          end
        end
      end

      it "raises an error if the requested association does not exist" do
        expect do
          get :show, params: { id: file_set, file: 'non-existant' }
        end.to raise_error Hyrax::ObjectNotFoundError
      end
    end
  end

  describe "derivative_download_options" do
    before do
      allow(controller).to receive(:default_file).and_return 'world.png'
    end
    subject { controller.send(:derivative_download_options) }

    it { is_expected.to eq(disposition: 'inline', type: 'image/png') }
  end

end
