# frozen_string_literal: true
# Update: hyrax5

require 'rails_helper'

RSpec.describe Hyrax::CollectionsController, clean_repo: true, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.hyrax_collection_controller_debug_verbose ).to eq( debug_verbose ) }
  end

  let(:user)  { factory_bot_create_user(:user) }
  let(:other) { build(:user) }

  let(:collection) do
    create(:public_collection_lw, title: ["My collection"],
           description: ["My incredibly detailed description of the collection"],
           user: user)
  end

  let(:asset1)         { create(:work, title: ["First of the Assets"], user: user) }
  let(:asset2)         { create(:work, title: ["Second of the Assets"], user: user) }
  let(:asset3)         { create(:work, title: ["Third of the Assets"], user: user) }
  let(:asset4)         { build(:collection_lw, title: ["First subcollection"], user: user) }
  let(:asset5)         { build(:collection_lw, title: ["Second subcollection"], user: user) }
  let(:unowned_asset)  { create(:work, user: other) }

  # TODO: when we get valkyrie working
  # let(:collection) do
  #   FactoryBot.valkyrie_create(:hyrax_collection,
  #                              :public,
  #                              title: ["My collection"],
  #                              description: ["My incredibly detailed description of the collection"],
  #                              edit_users: [user.user_key], read_users: [user.user_key])
  # end
  #
  # let(:asset1)        { FactoryBot.valkyrie_create(:work, title: ["First of the Assets"], edit_users: [user.user_key], read_users: [user.user_key]) }
  # let(:asset2)        { FactoryBot.valkyrie_create(:work, title: ["Second of the Assets"], edit_users: [user.user_key], read_users: [user.user_key]) }
  # let(:asset3)        { FactoryBot.valkyrie_create(:work, title: ["Third of the Assets"], edit_users: [user.user_key], read_users: [user.user_key]) }
  # let(:asset4)        { FactoryBot.valkyrie_create(:hyrax_collection, title: ["First subcollection"], edit_users: [user.user_key], read_users: [user.user_key]) }
  # let(:asset5)        { FactoryBot.valkyrie_create(:hyrax_collection, title: ["Second subcollection"], edit_users: [user.user_key], read_users: [user.user_key]) }
  # let(:unowned_asset) { FactoryBot.valkyrie_create(:work, user: other) }

  let(:collection_attrs) do
    { title: ['My First Collection'], description: ["The Description\r\n\r\nand more"] }
  end

  describe "#show" do # public landing page
    context "when signed in" do
      before do
        sign_in user
        if collection.is_a? Valkyrie::Resource
          Hyrax::Collections::CollectionMemberService.add_members(collection_id: collection.id,
                                                                  new_members: [asset1, asset2, asset3, asset4, asset5],
                                                                  user: user)
        else
          [asset1, asset2, asset3, asset4, asset5].each do |asset|
            asset.member_of_collections = [collection]
            asset.save
          end
        end
      end

      # it "returns the collection and its members", skip: true do # rubocop:disable RSpec/ExampleLength
        # TODO: fix this
      it "returns the collection and its members" do # rubocop:disable RSpec/ExampleLength
        expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Collections', Hyrax::Engine.routes.url_helpers.dashboard_collections_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'), {"aria-current" => "page"})
        get :show, params: { id: collection }
        expect(response).to be_successful
        expect(response).to render_template("layouts/hyrax/1_column")
        expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
        expect(assigns[:presenter].title).to match_array collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map(&:id)
        expect(assigns[:subcollection_docs].map(&:id)).to match_array [asset4, asset5].map(&:id)
        expect(assigns[:members_count]).to eq(3)
        expect(assigns[:subcollection_count]).to eq(2)
      end

      context "and searching" do
        it "returns some works and subcollections" do
          # "/collections/4m90dv529?utf8=%E2%9C%93&cq=King+Louie&sort="
          get :show, params: { id: collection, cq: "Second" }
          expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
          expect(assigns[:member_docs].map(&:id)).to match_array [asset2].map(&:id)
          expect(assigns[:subcollection_docs].map(&:id)).to match_array [asset5].map(&:id)
          expect(assigns[:members_count]).to eq(1)
          expect(assigns[:subcollection_count]).to eq(1)
        end
      end

      context 'when the page parameter is passed' do
        it 'loads the collection (paying no attention to the page param)' do
          get :show, params: { id: collection, page: '2' }
          expect(response).to be_successful
          expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
          expect(assigns[:presenter].to_s).to eq 'My collection'
        end
      end

      # context "without a referer", skip: true do
        # TODO: fix this
      context "without a referer" do
        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Collections', Hyrax::Engine.routes.url_helpers.dashboard_collections_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'), {"aria-current" => "page"})
          get :show, params: { id: collection }
          expect(response).to be_successful
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
        end

        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Collections', Hyrax::Engine.routes.url_helpers.dashboard_collections_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'), {"aria-current" => "page"})
          get :show, params: { id: collection }
          expect(response).to be_successful
        end
      end
    end

    context "not signed in" do
      it "does not show me files in the collection" do
        get :show, params: { id: collection }
        expect(assigns[:member_docs].count).to eq 0
        expect(assigns[:subcollection_docs].count).to eq 0
      end
    end

    context "without a referer" do
      it "sets breadcrumbs" do
        expect(controller).not_to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).not_to receive(:add_breadcrumb).with('Your Collections', Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
        expect(controller).not_to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'))

        get :show, params: { id: collection }
        expect(response).to be_successful
      end
    end

    context "with a referer" do
      before do
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "sets breadcrumbs" do
        expect(controller).not_to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).not_to receive(:add_breadcrumb).with('Your Collections', Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
        # expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'), "aria-current" => "page")
        get :show, params: { id: collection }
        expect(response).to be_successful
      end
    end
  end
end
