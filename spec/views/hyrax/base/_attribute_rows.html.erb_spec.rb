require 'rails_helper'

RSpec.describe 'hyrax/base/_attribute_rows.html.erb', type: :view do

  let(:main_app) { Rails.application.routes.url_helpers }

  let(:user) { create(:user) }

  context 'with rights statement' do
    let(:url) { "http://example.com" }
    let(:rights_statement_uri) { 'http://rightsstatements.org/vocab/InC/1.0/' }
    let(:ability) { double('ability') }
    let(:work) do
      stub_model(DataSet,
                 depositor: user.user_key,
                 related_url: [url],
                 rights_license: rights_statement_uri)
    end
    let(:solr_document) do
      SolrDocument.new(id: work.id,
                       has_model_ssim: 'DataSet',
                       depositor_tesim: user.user_key,
                       rights_license_tesim: rights_statement_uri,
                       related_url_tesim: [url])
    end
    # let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability) }
    let(:presenter) { Hyrax::DataSetPresenter.new(solr_document, ability) }

    let(:page) do
      render 'hyrax/base/attribute_rows', presenter: presenter
      Capybara::Node::Simple.new(rendered)
    end
    # let(:work_url) { "umrdr-testing.hydra.lib.umich.edu/concern/work/#{work.id}" }
    let(:work_url) { "/concern/work/#{work.id}" }

    before do
      allow(ability).to receive(:admin?).and_return false
    end

    it 'shows external link with icon for related url field' do
      expect(page).to have_selector '.glyphicon-new-window'
      expect(page).to have_link(url)
    end

    it 'shows rights statement with link to statement URL' do
      expect(page).to have_link("In Copyright", href: rights_statement_uri)
    end
  end

  context 'with rights statement other' do
    let(:url) { "http://example.com" }
    let(:rights_statement_other) { 'The value displayed for Other license.' }
    let(:ability) { double }
    let(:work) do
      stub_model(DataSet,
                 depositor: user.user_key,
                 related_url: [url],
                 rights_license: 'Other',
                 rights_license_other: rights_statement_other )
    end
    let(:solr_document) do
      SolrDocument.new(id: work.id,
                       has_model_ssim: 'DataSet',
                       rights_license_tesim: 'Other',
                       rights_license_other_tesim: rights_statement_other)
    end
    let(:presenter) { Hyrax::DataSetPresenter.new(solr_document, ability) }

    let(:page) do
      render 'hyrax/base/attribute_rows', presenter: presenter
      Capybara::Node::Simple.new(rendered)
    end
    let(:work_url) { "/concern/work/#{work.id}" }

    before do
      allow(ability).to receive(:admin?).and_return false
    end

    it 'shows rights statement with other value' do
      expect(page).to have_content rights_statement_other
    end
  end

end
