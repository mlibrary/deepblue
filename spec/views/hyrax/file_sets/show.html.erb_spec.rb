# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'hyrax/file_sets/show.html.erb', type: :view do

  include Devise::Test::ControllerHelpers

  let(:user) { double(user_key: 'sarah', twitter_handle: 'test') }
  let(:ability) { double( "ability" ) }
  let(:doc) do
    {
      "has_model_ssim" => ["FileSet"],
      :id => "123",
      "title_tesim" => ["My Title"]
    }
  end
  let(:parent_doc) do
    {
        "has_model_ssim" => ["DataSet"],
        :id => "456",
        "title_tesim" => ["My Work Title"]
    }
  end
  let(:solr_doc) { SolrDocument.new(doc) }
  let(:parent_solr_doc) { SolrDocument.new (parent_doc ) }
  # let(:parent) { create(:data_set_work, title: ['Parent Work'], user: user) }
  let(:parent_presenter) { Hyrax::DataSetPresenter.new(parent_solr_doc, ability) }
  let(:presenter) { Hyrax::DsFileSetPresenter.new(solr_doc, ability) }
  let(:mock_metadata) do
    {
      format: ["Tape"],
      long_term: ["x" * 255],
      multi_term: ["1", "2", "3", "4", "5", "6", "7", "8"],
      string_term: 'oops, I used a string instead of an array',
      logged_fixity_status: "Fixity checks have not yet been run on this file"
    }
  end

  before do
    allow(presenter).to receive(:fetch_parent_presenter).and_return(parent_presenter)
    view.lookup_context.prefixes.push 'hyrax/base'
    allow(view).to receive(:can?).with(:edit, SolrDocument).and_return(false)
    allow(ability).to receive(:can?).with(:edit, SolrDocument).and_return(false)
    allow(view).to receive(:can?).with(:edit, "123").and_return(false)
    allow(ability).to receive(:can?).with(:edit, "123").and_return(false)
    allow(ability).to receive(:can?).with(:download, "123").and_return(false)
    allow(ability).to receive(:admin?).and_return(false)
    # TODO - allow(presenter).to receive(:fixity_status).and_return(mock_metadata)
    assign(:presenter, presenter)
    assign(:document, solr_doc)
    # TODO - assign(:fixity_status, "none")
  end

  describe 'title heading' do
    before do
      stub_template 'hyrax/base/_modal_mint_doi' => 'Modal Mint'
      stub_template 'shared/_title_bar.html.erb' => 'Title Bar'
      stub_template 'shared/_citations.html.erb' => 'Citation'
      render
    end
    it 'shows the title' do
      expect(rendered).to have_selector 'h1', text: 'My Title'
    end
  end

  it "does not render single-use links" do
    expect(rendered).not_to have_selector('table.single-use-links')
  end

  it "does not render anonymous links" do
    expect(rendered).not_to have_selector('table.anonymous-links')
  end
end
