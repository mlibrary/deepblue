# frozen_string_literal: true
# Skip: hyrax4 - WebMock::NetConnectNotAllowedError
require 'rails_helper'

RSpec.describe 'autofilling the form from DOI', :js, skip: Rails.configuration.hyrax4_spec_skip do
  let(:model_class) do
    Class.new(DataSet) do
      include ::Deepblue::DoiBehavior
      include Hyrax::Doi::DataCiteDoiBehavior
    end
  end
  let(:form_class) do
    Class.new(Hyrax::DataSetForm) do
      include Hyrax::Doi::DoiFormBehavior
      include Hyrax::Doi::DataCiteDoiFormBehavior

      self.model_class = DataSet
    end
  end
  let(:helper_module) do
    Module.new do
      include ::BlacklightHelper
      include Hyrax::BlacklightOverride
      include Hyrax::HyraxHelperBehavior
      include Hyrax::Doi::HelperBehavior
    end
  end
  let(:solr_document_class) do
    Class.new(SolrDocument) do
      include Hyrax::Doi::SolrDocument::DoiBehavior
      include Hyrax::Doi::SolrDocument::DataCiteDoiBehavior
    end
  end
  let(:controller_class) do
    Class.new(::ApplicationController) do
      # Adds Hyrax behaviors to the controller.
      include Hyrax::WorksControllerBehavior
      include Hyrax::BreadcrumbsForWorks
      self.curation_concern_type = DataSet

      # Use this line if you want to use a custom presenter
      self.show_presenter = Hyrax::DataSetPresenter

      helper Rails.helpers
    end
  end

  let(:user) { factory_bot_create_user(:admin) }
  let(:input) { File.join(Rails.root, 'spec', 'fixtures', 'datacite.json') }
  let(:metadata) { Bolognese::Metadata.new(input: input) }

  before do
    # Override test app classes and module to simulate generators having been run
    stub_const("DataSet", model_class)
    stub_const("Hyrax::DataSetForm", form_class)
    stub_const("HyraxHelper", helper_module)
    stub_const("SolrDocument", solr_document_class)
    stub_const("Hyrax::DataSetsController", controller_class)

    # Mock Bolognese so it doesn't have to make a network request
    allow(Bolognese::Metadata).to receive(:new).and_return(metadata)

    allow_any_instance_of(Ability).to receive(:admin_set_with_deposit?).and_return(true)
    allow_any_instance_of(Ability).to receive(:can?).and_call_original
    allow_any_instance_of(Ability).to receive(:can?).with(:new, anything).and_return(true)

    sign_in user
  end

  scenario 'autofills the form' do
    visit "/concern/generic_works/new"
    fill_in 'generic_work_doi', with: '10.5438/4k3m-nyvg'
    accept_confirm do
      click_link "doi-autofill-btn"
    end

    # expect form fields have been filled in
    click_link 'Additional fields'
    expect(page).to have_field('generic_work_title', with: 'Eating your own Dog Food')
    expect(page).to have_field('generic_work_creator', with: 'Fenner, Martin')
    expect(page).to have_field('generic_work_description', with: 'Eating your own dog food is a slang term to describe that an organization '\
                                                                 'should itself use the products and services it provides. For DataCite this '\
                                                                 'means that we should use DOIs with appropriate metadata and strategies for '\
                                                                 'long-term preservation for...')
    expect(page).to have_field('generic_work_keyword', with: 'datacite')
    expect(page).to have_field('generic_work_keyword', with: 'doi')
    expect(page).to have_field('generic_work_keyword', with: 'metadata')
    expect(page).to have_field('generic_work_publisher', with: 'DataCite')
    expect(page).to have_field('generic_work_date_created', with: '2016')
    expect(page).to have_field('generic_work_identifier', with: 'MS-49-3632-5083')

    # expect page to have forwarded to metadata tab
    expect(URI.parse(page.current_url).fragment).to eq 'metadata'
  end
end
