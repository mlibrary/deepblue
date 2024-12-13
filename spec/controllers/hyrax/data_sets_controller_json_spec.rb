# Skip: hyrax4 - try it
require 'rails_helper'
include Warden::Test::Helpers

# This tests the Hyrax::WorksControllerBehavior module
RSpec.describe Hyrax::DataSetsController, skip: false do

  include Devise::Test::ControllerHelpers
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:user) { factory_bot_create_user(:user) }

  before { sign_in user }

  context "JSON" do
    let(:admin_set) { create(:admin_set, id: 'admin_set_1', with_permission_template: { with_active_workflow: true }) }

    let(:resource) { create(:private_data_set, user: user, admin_set_id: admin_set.id) }
    let(:resource_request) { get :show, params: { id: resource, format: :json } }

    subject { response }

    describe "unauthorized", skip: true do
      before do
        sign_out user
        resource_request
      end
      it { is_expected.to respond_unauthorized }
    end

    describe "forbidden", skip: true do
      before do
        sign_in factory_bot_create_user(:user)
        resource_request
      end
      it { is_expected.to respond_forbidden }
    end

    describe 'created', skip: true do
      let(:actor) { double(create: create_status) }
      let(:create_status) { true }
      let(:model) { stub_model(DataSet) }

      before do
        allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
        allow(controller).to receive(:curation_concern).and_return(model)
        post :create, params: { data_set: { title: ['a title'] }, format: :json }
      end

      it "returns 201, renders show template sets location header" do
        # Ensure that @curation_concern is set for jbuilder template to use
        expect(assigns[:curation_concern]).to be_instance_of DataSet
        expect(controller).to render_template('hyrax/base/show')
        expect(response.code).to eq "201"
        expect(response.location).to eq main_app.hyrax_data_set_path(model, locale: 'en')
      end
    end

    # The clean is here because this test depends on the repo not having an AdminSet/PermissionTemplate created yet
    describe 'failed create', :clean_repo, skip: true do
      before { post :create, params: { data_set: {}, format: :json } }
      it "returns 422 and the errors" do
        created_resource = assigns[:curation_concern]
        expect(response).to respond_unprocessable_entity(errors: created_resource.errors.messages.as_json)
      end
    end

    describe 'found', skip: true do
      before do
        allow(controller).to receive(:skip_send_irus_analytics?).with(any_args).and_return true
        resource_request
      end
      it "returns json of the work" do
        # Ensure that @curation_concern is set for jbuilder template to use
        expect(assigns[:curation_concern]).to be_instance_of DataSet
        expect(controller).to render_template('hyrax/base/show')
        expect(response.code).to eq "200"
      end
    end

    describe 'updated', skip: true do
      before { put :update, params: { id: resource, data_set: { title: ['updated title'] }, format: :json } }
      it "returns 200, renders show template sets location header" do
        # Ensure that @curation_concern is set for jbuilder template to use
        expect(assigns[:curation_concern]).to be_instance_of DataSet
        expect(controller).to render_template('hyrax/base/show')
        expect(response.code).to eq "200"
        created_resource = assigns[:curation_concern]
        expect(response.location).to eq main_app.hyrax_data_set_path(created_resource, locale: 'en')
      end
    end

    describe 'failed update', skip: true do
      before { post :update, params: { id: resource, data_set: { title: [''] }, format: :json } }
      it "returns 422 and the errors" do
        expect(response).to respond_unprocessable_entity(errors: { title: ["Your work must have a title."] })
      end
    end
  end
end
