require 'rails_helper'

RSpec.describe 'hyrax/file_sets/_actions.html.erb', type: :view do

  # TODO: file too big to download
  # TODO: file in between size warning
  # TODO: single use link

  include Devise::Test::ControllerHelpers

  let(:solr_document) { double( "Solr Doc", id: 'file_set_id', visibility: "open", file_size: 1 ) }
  let(:user) { build(:user) }
  let(:ability) { Ability.new(user) }
  let(:presenter) { Hyrax::DsFileSetPresenter.new(solr_document, ability) }
  let(:user_key) { 'a_user_key' }
  let( :parent_id ) { '888888' }
  let( :parent_title ) { ['foo', 'bar'] }
  let(:parent_attributes) do
    { "id" => parent_id,
      "title_tesim" => parent_title,
      "human_readable_type_tesim" => ["DataSet Work"],
      "has_model_ssim" => ["DataSet"],
      "date_created_tesim" => ['an unformatted date'],
      "depositor_tesim" => user_key }
  end
  let(:parent_solr_document) { SolrDocument.new( parent_attributes ) }
  let(:request) { double(host: 'example.org', base_url: 'http://example.org') }
  let(:parent_presenter) { Hyrax::DataSetPresenter.new( parent_solr_document, ability, request ) }
  let( :parent_data_set ) { create( :public_data_set, id: parent_id, user: user, title: parent_title ) }
  let ( :workflow ) { double( "workflow" ) }

  before do
    allow( presenter ).to receive( :parent ).and_return parent_presenter
  end

  context 'with download permission' do
    before do
      allow( view ).to receive( :presenter ).and_return( parent_presenter )
      assign( :presenter, parent_presenter )
      assign( :parent_presenter, parent_presenter )
      allow( presenter ).to receive( :user_can_perform_any_action? ).and_return true
      allow( parent_presenter ).to receive( :tombstone ).and_return nil
      allow( workflow ).to receive( :state ).and_return "pending_review"
      allow( parent_presenter ).to receive( :workflow ).and_return workflow
      allow( presenter ).to receive( :parent_data_set ).and_return parent_data_set
      allow( presenter ).to receive( :can_delete_file? ).and_return false
      allow( presenter ).to receive( :can_edit_file? ).and_return false
      allow( presenter ).to receive( :can_view_file? ).and_return true
      allow( presenter ).to receive( :can_download_file? ).and_return true
      allow( presenter ).to receive( :anonymous_show? ).and_return false
      allow( ability ).to receive( :can? ).with( :destroy, presenter.id ).and_return false
      allow( ability ).to receive( :can? ).with( :download, presenter.id ).and_return true
      allow( ability ).to receive( :can? ).with( :edit, presenter.id ).and_return false
      assign( :member, presenter )
      render 'hyrax/file_sets/actions', presenter: parent_presenter, member: presenter
    end

    it "includes google analytics data in the download link" do
      expect(rendered).to have_css('a#file_download')
      expect(rendered).to have_selector("a[data-label=\"#{presenter.id}\"]")
    end
  end

  context 'with no permission' do
    before do
      allow( presenter ).to receive(:user_can_perform_any_action?).and_return false
      render 'hyrax/file_sets/actions', member: presenter
    end

    it "renders nothing" do
      expect(rendered).to eq("<!-- view/file_sets/_actions.html.erb -->\n")
    end
  end

end
