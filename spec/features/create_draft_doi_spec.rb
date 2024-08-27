# frozen_string_literal: true
# Skip: Webdrivers::VersionError: Unable to find latest point release version for 127.0.6533...
require 'rails_helper'

RSpec.describe 'creating a draft DOI', :datacite_api, :js, skip: true do
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

  let(:prefix) { '10.1234' }
  let(:user) { create(:admin) }

  before do
    # Override test app classes and module to simulate generators having been run
    stub_const("DataSet", model_class)
    stub_const("Hyrax::DataSetForm", form_class)
    stub_const("HyraxHelper", helper_module)
    stub_const("SolrDocument", solr_document_class)
    stub_const("Hyrax::DataSetsController", controller_class)

    Hyrax.config.identifier_registrars = { datacite: ::Deepblue::DataCiteRegistrar }
    ::Deepblue::DataCiteRegistrar.mode = :test
    ::Deepblue::DataCiteRegistrar.prefix = prefix
    ::Deepblue::DataCiteRegistrar.username = 'username'
    ::Deepblue::DataCiteRegistrar.password = 'password'

    allow_any_instance_of(Ability).to receive(:admin_set_with_deposit?).and_return(true)
    allow_any_instance_of(Ability).to receive(:can?).and_call_original
    allow_any_instance_of(Ability).to receive(:can?).with(:new, anything).and_return(true)

    sign_in user
  end

  scenario 'creates a draft DOI on the form' do
    visit "/concern/generic_works/new"
    click_link "doi-create-draft-btn"
    expect(page).to have_field('generic_work_doi', with: '10.1234/draft-doi')
  end

  describe "when the DOI has been disabled" do
    before do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:doi_minting, false)

      visit "/concern/generic_works/new"
    end

    scenario "disables the button" do
      # For some reason page.find_button('#doi-create-draft-btn', disabled: true) isn't working
      expect(page.find('#doi-create-draft-btn')[:disabled]).to eq "true"
    end

    scenario "hides the minting options" do
      expect(page).not_to have_selector(".set-doi-status-when-public")
    end
  end
end
