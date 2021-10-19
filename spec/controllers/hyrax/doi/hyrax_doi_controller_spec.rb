# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Doi::HyraxDoiController, :datacite_api, type: :controller, skip: true do
  routes { Rails.application.routes }

  let(:prefix) { '10.1234' }

  before do
    Hyrax.config.identifier_registrars = { datacite: ::Deepblue::DataCiteRegistrar }
    ::Deepblue::DataCiteRegistrar.mode = :test
    ::Deepblue::DataCiteRegistrar.prefix = prefix
    ::Deepblue::DataCiteRegistrar.username = 'username'
    ::Deepblue::DataCiteRegistrar.password = 'password'
  end

  shared_context 'with a logged in admin user' do
    let(:user) { create(:admin) }

    before do
      allow_any_instance_of(Ability).to receive(:admin_set_with_deposit?).and_return(true)
      sign_in user
    end
  end

  describe 'create_draft_doi' do
    context 'authorization' do
      context 'when unauthorized' do
        it 'redirects to new user login' do
          get :create_draft_doi
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    context 'JS format' do
      include_context 'with a logged in admin user'

      it 'returns a JS with the new DOI' do
        get :create_draft_doi, params: { format: :js, curation_concern: 'generic_work' }, xhr: true

        expect(response).to have_http_status(:created)
        expect(response.body).to include '10.1234/draft-doi'
      end

      context 'with datacite error' do
        before do
          allow_any_instance_of(::Deepblue::DoiMinting2021Service).to receive(:create_draft_doi).and_raise(::Deepblue::DoiMinting2021Service::Error, "Error")
        end

        it 'returns a failure' do
          get :create_draft_doi, params: { format: :js, curation_concern: 'generic_work' }, xhr: true

          expect(response).to have_http_status(:internal_server_error)
          expect(response.body).to be_present
        end
      end
    end

    context 'JSON format' do
      include_context 'with a logged in admin user'

      it 'returns JSON with the new DOI' do
        get :create_draft_doi, params: { format: :json, curation_concern: 'generic_work' }

        expect(response).to have_http_status(:created)
        expect(response.body).to include '10.1234/draft-doi'
      end

      context 'with datacite error' do
        before do
          allow_any_instance_of(::Deepblue::DoiMinting2021Service).to receive(:create_draft_doi).and_raise(::Deepblue::DoiMinting2021Service::Error, "Error")
        end

        it 'returns a failure' do
          get :create_draft_doi, params: { format: :json, curation_concern: 'generic_work' }

          expect(response).to have_http_status(:internal_server_error)
          expect(response.body).to be_present
        end
      end
    end
  end

  describe 'autofill' do
    context 'authorization' do
      context 'when unauthorized' do
        it 'redirects to new user login' do
          get :autofill
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    context 'JS format' do
      include_context 'with a logged in admin user'

      context 'with valid doi' do
        let(:input) { File.join(Rails.root, 'spec', 'fixtures', 'datacite.json') }
        let(:metadata) { Bolognese::Metadata.new(input: input) }
        let(:model_class) do
          Class.new(GenericWork) do
            include ::Deepblue::DoiBehavior

            # Defined here for ActiveModel::Validations error messages
            def self.name
              "WorkWithDoi"
            end
          end
        end

        before do
          allow(Bolognese::Metadata).to receive(:new).and_return(metadata)
        end

        it 'returns autofill JS' do
          get :autofill, params: { format: :js, curation_concern: 'work_with_doi', doi: '10.5438/4k3m-nyvg' }, xhr: true

          expect(response).to have_http_status(:ok)
          expect(response.body).to include '10.5438/4k3m-nyvg'
        end
      end

      context 'with invalid doi' do
        let(:metadata) { Bolognese::Metadata.new.tap { |m| m.meta = {} } }

        before do
          allow(Bolognese::Metadata).to receive(:new).and_return(metadata)
        end

        it 'returns a failure' do
          get :autofill, params: { format: :js, curation_concern: 'generic_work', doi: 'abcd' }, xhr: true

          expect(response).to have_http_status(:internal_server_error)
          expect(response.body).to be_present
        end
      end
    end
  end
end
