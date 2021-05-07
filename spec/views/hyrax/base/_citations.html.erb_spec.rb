require 'rails_helper'

RSpec.describe 'hyrax/base/_citations.html.erb', type: :view, skip: false do
  let(:user) { create(:user) }
  let(:object_profile) { ["{\"id\":\"999\"}"] }
  let(:contributor) { ['Frodo'] }
  let(:creator)     { ['Bilbo'] }
  let(:solr_document) do
    SolrDocument.new(
      id: '999',
      object_profile_ssm: object_profile,
      has_model_ssim: ['DataSet'],
      human_readable_type_tesim: ['Work'],
      contributor_tesim: contributor,
      creator_tesim: creator,
      title_tesim: ['The Title'],
      rights_tesim: ['http://creativecommons.org/licenses/by/3.0/us/']
    )
  end
  let(:ability) { Ability.new(user) }
  let(:presenter) do
    Hyrax::WorkShowPresenter.new(solr_document, ability)
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    assign( :presenter, presenter )
    assign( :work, solr_document )
    Hyrax.config.citations = citations
    allow(controller).to receive(:can?).with(:edit, presenter).and_return(false)
    render 'hyrax/base/citations', presenter: presenter
  end

  context 'when enabled' do
    let(:citations) { true }

    it 'appears on page' do
      # expect(page).to have_selector('a#citations', count: 1)
      expect(rendered).to include "<span class='citation-author'>Bilbo.</span> <span class='citation-title'>The Title</span> [Data set], University of Michigan - Deep Blue Data."
    end
  end

  context 'when disabled' do
    let(:citations) { false }

    it 'does not appear on page' do
      expect(rendered).to_not include "<span class='citation-author'>Bilbo.</span> <span class='citation-title'>The Title</span> [Data set], University of Michigan - Deep Blue Data."
    end
  end
end
