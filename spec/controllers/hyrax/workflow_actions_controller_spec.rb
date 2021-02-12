require 'rails_helper'

RSpec.describe Hyrax::WorkflowActionsController, type: :controller, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }
  let(:main_app) { Rails.application.routes.url_helpers }

  let(:user) { create(:user) }
  let(:data_set) { stub_model(DataSet, id: '123') }
  let(:form) { instance_double(Hyrax::Forms::WorkflowActionForm) }

  routes { Rails.application.routes }

  before do
    allow(ActiveFedora::Base).to receive(:find).with(data_set.to_param).and_return(data_set)
    allow(data_set).to receive(:persisted?).and_return(true)
    allow(Hyrax::Forms::WorkflowActionForm).to receive(:new).and_return(form)
  end

  describe '#update' do
    it 'will redirect to login path if user not authenticated' do
      put :update, params: { id: data_set.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to redirect_to(main_app.user_session_path)
    end

    it 'will render :unauthorized when action is not valid for the given user' do
      expect(form).to receive(:save).and_return(false)
      sign_in(user)

      put :update, params: { id: data_set.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to be_unauthorized
    end

    it 'will redirect when the form is successfully save' do
      expect(form).to receive(:save).and_return(true)
      sign_in(user)

      put :update, params: { id: data_set.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to redirect_to(main_app.hyrax_data_set_path(data_set, locale: 'en'))
    end

    context 'when responding to json' do
      it 'will render :ok when the form is successfully saved' do
        expect(form).to receive(:save).and_return(true)
        sign_in(user)

        put :update, params: { id: data_set.to_param, workflow_action: { name: 'advance', comment: '' } }, format: :json
        expect(response.status).to eq 200
      end

      it 'will render :unprocessable_entity when the form fails to save' do
        expect(form).to receive(:save).and_return(false)
        sign_in(user)

        put :update, params: { id: data_set.to_param, workflow_action: { name: 'advance', comment: '' } }, format: :json
        expect(response.status).to eq 422
      end
    end
  end
end
