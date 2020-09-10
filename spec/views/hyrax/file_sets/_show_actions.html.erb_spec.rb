require 'rails_helper'

RSpec.describe 'hyrax/file_sets/_show_actions.html.erb', type: :view do
  let(:user) { create(:user) }
  let(:object_profile) { ["{\"id\":\"999\"}"] }
  let(:contributor) { ['Frodo'] }
  let(:creator)     { ['Bilbo'] }
  let(:solr_document) do
    SolrDocument.new(
      id: '999',
      object_profile_ssm: object_profile,
      has_model_ssim: ['FileSet'],
      human_readable_type_tesim: ['File'],
      contributor_tesim: contributor,
      creator_tesim: creator,
      rights_tesim: ['http://creativecommons.org/licenses/by/3.0/us/']
    )
  end
  let(:parent_doc) do
    {
        "has_model_ssim" => ["DataSet"],
        :id => "456",
        "title_tesim" => ["My Work Title"]
    }
  end
  let(:parent_solr_doc) { SolrDocument.new (parent_doc ) }
  let(:parent_presenter) { Hyrax::DataSetPresenter.new(parent_solr_doc, ability) }
  let(:ability) { Ability.new(user) }
  let(:presenter) do
    Hyrax::DsFileSetPresenter.new(solr_document, ability)
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }

  describe 'citations' do
    before do
      allow( presenter ).to receive(:fetch_parent_presenter).and_return(parent_presenter)
      Hyrax.config.citations = citations
      allow( ability ).to receive(:can?).with(:edit, solr_document).and_return(false)
      assign( :presenter, presenter )
      allow( presenter ).to receive( :parent_data_set ).and_return parent_solr_doc
      view.lookup_context.view_paths.push 'app/views/hyrax/base'
      render
    end

    context 'when enabled' do
      let(:citations) { true }

      it 'does not appear on page' do
        expect(page).to have_no_selector('a#citations')
      end
    end

    context 'when disabled' do
      let(:citations) { false }

      it 'does not appear on page' do
        expect(page).to have_no_selector('a#citations')
      end
    end
  end

  describe 'editor' do
    before do
      allow( presenter ).to receive(:fetch_parent_presenter).and_return(parent_presenter)
      allow( presenter ).to receive( :editor? ).and_return(true)
      assign( :presenter, presenter )
      allow( presenter ).to receive( :parent_data_set ).and_return parent_solr_doc
      view.lookup_context.view_paths.push 'app/views/hyrax/base'
      render
    end

    it 'renders actions for the user' do
      expect(page).to have_content "Edit"
      expect(page).to have_content "Delete"
      expect(page).to have_content "View File Analytics"
      expect(page).to have_link("Edit")
      expect(page).to have_link("Delete")
      expect(page).to have_link("View File Analytics")
    end
  end

end
