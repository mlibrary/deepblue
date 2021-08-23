require 'rails_helper'

RSpec.describe 'hyrax/base/_attributes.html.erb' do
  let( :id ) { '123id' }
  let( :authoremail ) { 'author@email.com' }
  let( :depositor )   { 'depositor@email.com' }
  let( :creator )     { 'Bilbo' }
  let( :contributor ) { 'Frodo' }
  let( :description ) { ['Lorem ipsum < lorem ipsum. http://my.link.com'] }
  let( :methodology ) { ['The Methodology'] }
  let( :subject )     { 'history' }

  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) do
    {
      id: id,
      Solrizer.solr_name( 'has_model', :symbol ) => ["DataSet"],
      Solrizer.solr_name( 'authoremail', :symbol ) => authoremail,
      Solrizer.solr_name( 'depositor', :symbol ) => depositor,
      contributor_tesim: contributor,
      creator_tesim: creator,
      description_tesim: description,
      methodology_tesim: methodology,
      rights_license_tesim: ['Rights License Value'],
      subject_tesim: subject
    }
  end
  let(:ability) { double(admin?: true) }
  let(:presenter) do
    Hyrax::DataSetPresenter.new( solr_document, ability )
  end
  let(:doc) { Nokogiri::HTML(rendered) }

  before do
    allow(presenter).to receive(:id).and_return id
    allow(presenter).to receive(:member_of_collection_presenters).and_return([])
    allow(presenter).to receive(:tombstone_permissions_hack? ).and_return false
    allow(presenter).to receive(:edit_groups).and_return []
    allow(presenter).to receive(:edit_users).and_return []
    allow(presenter).to receive(:read_groups).and_return []
    allow(presenter).to receive(:read_users).and_return []
    allow(view).to receive(:dom_class) { '' }

    stub_template 'shared/_show_curation_notes.html.erb' => ''
    render 'hyrax/base/attributes', presenter: presenter
  end

  it 'has links to search for other objects with the same metadata' do
    expect(rendered).to have_link(creator)
    expect(rendered).to have_link(contributor)
    expect(rendered).to have_link(subject)
  end

end
