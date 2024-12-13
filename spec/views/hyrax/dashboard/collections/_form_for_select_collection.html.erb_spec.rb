require 'rails_helper'

RSpec.describe 'hyrax/dashboard/collections/_form_for_select_collection.html.erb', type: :view, skip: false do

  include Devise::Test::ControllerHelpers

  let(:collections) do
    [
      { id: 1234, create_date: Time.zone.parse('Thu, 13 Aug 2015 14:20:22 +0100') },
      { id: 1235, create_date: Time.zone.parse('Thu, 13 Aug 2015 14:18:22 +0100') },
      { id: 1236, create_date: Time.zone.parse('Thu, 13 Aug 2015 14:16:22 +0100') },
      { id: 1237, create_date: Time.zone.parse('Thu, 13 Aug 2015 14:29:22 +0100') }
    ]
  end
  let(:solr_collections) do
    collections.map do |c|
      doc = { id: c[:id],
              "has_model_ssim" => ["Collection"],
              "title_tesim" => ["Title 1"],
              "system_create_dtsi" => c[:create_date].to_s }
      SolrDocument.new(doc)
    end
  end
  let( :user_collections ) { solr_collections }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  context 'for admin user' do
    let(:user) { factory_bot_create_user(:admin) }
    let(:ability) { Ability.new(user) }

    before do
      allow(ability).to receive(:admin?).and_return true
      allow(view).to receive(:current_ability).and_return(ability)
      allow(view).to receive(:current_user).and_return( user )
    end

    it "uses autocomplete with access deposit when non-admin" do
      render 'hyrax/dashboard/collections/form_for_select_collection',
             user_collections: user_collections
      expect(page).to have_selector('input[data-autocomplete-url="/authorities/search/collections"]')
    end
  end

  context 'for normal user' do
    let(:user) { factory_bot_create_user(:user) }
    let(:ability) { Ability.new(user) }

    before do
      allow(ability).to receive(:admin?).and_return false
      allow(view).to receive(:current_ability).and_return(ability)
      allow(view).to receive(:current_user).and_return( user )
    end

    it "uses autocomplete with access deposit when non-admin" do
      render 'hyrax/dashboard/collections/form_for_select_collection',
             user_collections: user_collections
      expect(page).to have_selector('input[data-autocomplete-url="/authorities/search/collections?access=deposit"]')
    end
  end

  context 'when a collection is specified' do
    let(:collection_id) { collections[2][:id] }
    let(:collection_label) { collections[2]["title_tesim"] }

    it "selects the right collection when instructed to do so" do
      assign(:add_works_to_collection, collection_id)
      assign(:add_works_to_collection_label, collection_label)
      render 'hyrax/dashboard/collections/form_for_select_collection',
             user_collections: user_collections
      expect(page).to have_selector "#member_of_collection_ids[value=\"#{collection_id}\"]", visible: false
      expect(page).to have_selector "#member_of_collection_label", text: collection_label
    end
  end

end
