# frozen_string_literal: true
# Update: hyrax4
# Update: hyrax5

require 'rails_helper'

RSpec.describe Hyrax::CollectionPresenter, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.collection_presenter_debug_verbose ).to eq( debug_verbose ) }
  end

  subject(:presenter) { described_class.new(solr_doc, ability) }

  let(:collection) do
    build(:hyrax_collection,
          id: 'adc12v',
          # hyrax2 version commented out
          # description: ['a nice collection'],
          # based_near: ['Over there'],
          # title: ['A clever title'],
          # keyword: ['neologism'],
          # resource_type: ['Collection'],
          # referenced_by: ['Referenced by This'],
          # related_url: ['http://example.com/'],
          # date_created: ['some date'])
          title: ['A clever title'])
   end
   let(:active_fedora_collection) do
     build(:collection_lw,
          id: 'adc12v',
          description: ['a nice collection'],
          based_near: ['Over there'],
          title: ['A clever title'],
          keyword: ['neologism'],
          resource_type: ['Collection'],
          referenced_by: ['Referenced by This'],
          related_url: ['http://example.com/'],
          date_created: ['some date'],
          with_solr_document: true)
  end
  let(:active_fedora_solr_hash) do
    active_fedora_collection.to_solr
  end

  let(:ability) { double(::Ability) }
  let(:solr_doc) { SolrDocument.new(solr_hash) }
  let(:solr_hash) { Hyrax::ValkyrieIndexer.for(resource: collection).to_solr }
  let(:user) { factory_bot_create_user(:user) }

  describe ".terms" do
    subject { described_class.terms }

    it do
      is_expected.to eq [:total_items,
                         :alternative_title,
                         :size,
                         :resource_type,
                         :creator,
                         :contributor,
                         :keyword,
                         :license,
                         :publisher,
                         :doi,
                         :date_created,
                         :subject_discipline,
                         :language,
                         :identifier,
                         :based_near,
                         :related_url,
                         :referenced_by]
    end
  end

  describe ".admin_only_terms" do
    subject { described_class.admin_only_terms }

    it do
      is_expected.to eq [:edit_groups,
                         :edit_people,
                         :read_groups]
    end
  end

  describe "collection type methods" do
    it { is_expected.to delegate_method(:collection_type_is_nestable?).to(:collection_type).as(:nestable?) }
    it { is_expected.to delegate_method(:collection_type_is_brandable?).to(:collection_type).as(:brandable?) }
    it { is_expected.to delegate_method(:collection_type_is_discoverable?).to(:collection_type).as(:discoverable?) }
    it { is_expected.to delegate_method(:collection_type_is_sharable?).to(:collection_type).as(:sharable?) }
    it { is_expected.to delegate_method(:collection_type_is_share_applies_to_new_works?).to(:collection_type).as(:share_applies_to_new_works?) }
    it { is_expected.to delegate_method(:collection_type_is_allow_multiple_membership?).to(:collection_type).as(:allow_multiple_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_require_membership?).to(:collection_type).as(:require_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_workflow?).to(:collection_type).as(:assigns_workflow?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_visibility?).to(:collection_type).as(:assigns_visibility?) }

    it "sets a default value on subcollection_counts" do
      expect(subject.subcollection_count).to eq(0)
    end

    it { is_expected.to respond_to(:subcollection_count=).with(1).argument }

    it "provides the amount of subcollections when there are none" do
      subject.subcollection_count = nil
      expect(subject.subcollection_count).to eq(0)
    end

    it "provides the amount of subcollections when they exist" do
      expect(subject.subcollection_count = 5).to eq(5)
    end
  end

  describe '#collection_type' do
    let(:collection_type) { create(:collection_type) }

    describe 'when solr_document#collection_type_gid exists' do
      let(:collection) { FactoryBot.build(:collection_lw, collection_type: collection_type) }
      let(:solr_doc) { SolrDocument.new(collection.to_solr) }

      it 'finds the collection type based on the solr_document#collection_type_gid if one exists' do
        expect(presenter.collection_type).to eq(collection_type)
      end
    end
  end

  describe "#resource_type" do
    let(:collection) { active_fedora_collection }
    let(:solr_hash) { active_fedora_solr_hash }
    it 'has resource_type' do
      expect(presenter).to have_attributes resource_type: collection.resource_type
    end
  end

  describe "#terms_with_values" do
    let(:collection) { active_fedora_collection }
    let(:solr_hash) { active_fedora_solr_hash }

    before do
      allow(ability).to receive(:admin?).and_return false
    end

    it 'gives the list of terms that have values' do
      expect(presenter.terms_with_values)
        .to contain_exactly(:total_items,
                            # :size,
                            :resource_type,
                            :keyword,
                            :date_created,
                            :based_near,
                            :referenced_by,
                            :related_url)
    end
  end

  # describe "#terms_with_values2" do
  #   # DBD actually supports size, but not this way
  #   subject { presenter.terms_with_values }
  #
  #   before do
  #     allow(ability).to receive(:admin?).and_return false
  #   end
  #
  #   it do
  #     is_expected.to eq [:total_items,
  #                        # :size,
  #                        :resource_type,
  #                        :keyword,
  #                        :date_created,
  #                        :based_near,
  #                        :referenced_by,
  #                        :related_url]
  #   end
  # end

  describe "#terms_with_values when admin" do
    # DBD actually supports size, but not this way
    let(:collection) { active_fedora_collection }
    let(:solr_hash) { active_fedora_solr_hash }
    # subject { presenter.terms_with_values }

    before do
      allow(ability).to receive(:admin?).and_return true
    end

    it do
      expect(presenter.terms_with_values)
        .to contain_exactly(:total_items,
                            # :size,
                            :resource_type,
                            :keyword,
                            :date_created,
                            :based_near,
                            :referenced_by,
                            :related_url,
                            :edit_people)
      # :edit_people,
      # :read_groups] # TODO: why are these missing now? hyrax v3
    end
  end

  describe '#to_s' do
    it { expect(presenter.to_s).to eq collection.title.first }
  end

  describe "#title" do
    it { is_expected.to have_attributes title: collection.title }
  end

  describe '#keyword' do
    let(:collection) { active_fedora_collection }
    let(:solr_hash) { active_fedora_solr_hash }
    it { is_expected.to have_attributes keyword: collection.keyword }
  end

  describe "#based_near" do
    let(:collection) { active_fedora_collection }
    let(:solr_hash) { active_fedora_solr_hash }
    it { is_expected.to have_attributes based_near: collection.based_near }
  end

  describe "#related_url" do
    let(:collection) { active_fedora_collection }
    let(:solr_hash) { active_fedora_solr_hash }
    it { is_expected.to have_attributes related_url: collection.related_url }
  end

  describe '#to_key' do
    let(:collection) { active_fedora_collection }
    let(:solr_hash) { active_fedora_solr_hash }
    it { expect(presenter.to_key).to eq ['adc12v'] }
  end

  describe '#size' do
    let(:collection) { active_fedora_collection }
    let(:solr_hash) { active_fedora_solr_hash }
    # DBD actually supports size, but not this way
    it 'returns a hard-coded string and issues a deprecation warning' do
      expect(Deprecation).to_not receive(:warn)
      # expect(presenter.size).to eq('unknown')
    end
  end

  describe "#total_items", :clean_repo do
    # hyrax2 # subject { presenter.total_items }

    context "empty collection", skip: Rails.configuration.hyrax5_spec_skip do
      let(:ability) { double(::Ability, user_groups: ['public'], current_user: user) }
      #hyrax5 - let(:user) { factory_bot_create_user(:user) }
      let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }

      before { allow(ability).to receive(:admin?).and_return(false) }

      it 'returns 0' do
        expect(presenter.total_items).to eq 0
      end
    end

    context "collection with work", skip: Rails.configuration.hyrax5_spec_skip do
      let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }
      let!(:data_set) { FactoryBot.valkyrie_create(:hyrax_work, member_of_collection_ids: [collection.id]) }

      it 'returns 1' do
        expect(presenter.total_items).to eq 1
      end
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), nil) }

      it 'returns 0' do
        expect(presenter.total_items).to eq 0
      end
    end
  end

  describe "#total_viewable_items", :clean_repo do
    subject { presenter.total_viewable_items }
    let(:ability) { double(::Ability, user_groups: ['public'], current_user: user) }
    #hyrax5 - let(:user) { factory_bot_create_user(:user) }
    let(:collection) { FactoryBot.create(:collection_lw) }
    let(:solr_hash) { collection.to_solr }

    before { allow(ability).to receive(:admin?).and_return(false) }

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private work", skip: true do
      # TODO: figure out why the member work is visible
      let!(:data_set) { create(:private_work, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with private collection" do
      let!(:data_set) { build(:private_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public work" do
      let!(:data_set) { create(:public_work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public collection" do
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:data_set) { create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 2 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#total_viewable_works", :clean_repo do
    subject { presenter.total_viewable_works }
    let(:ability) { double(::Ability, user_groups: ['public'], current_user: user) }
    #hyrax5 - let(:user) { factory_bot_create_user(:user) }
    let(:collection) { FactoryBot.create(:collection_lw) }
    let(:solr_hash) { collection.to_solr }

    before { allow(ability).to receive(:admin?).and_return(false) }

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private work", skip: true do
      # TODO: figure out why the member work is visible
      let!(:data_set) { create(:private_work, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public work" do
      let!(:data_set) { create(:public_work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:data_set) { create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#total_viewable_collections", :clean_repo do
    subject { presenter.total_viewable_collections }
    let(:ability) { double(::Ability, user_groups: ['public'], current_user: user) }
    #hyrax5 - let(:user) { factory_bot_create_user(:user) }
    let(:collection) { FactoryBot.create(:collection_lw) }
    let(:solr_hash) { collection.to_solr }

    before { allow(ability).to receive(:admin?).and_return(false) }

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private collection" do
      let!(:subcollection) { build(:private_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public collection" do
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:data_set) { create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#parent_collection_count" do
    subject { presenter.parent_collection_count }

    let(:parent_collections) { double(Object, documents: parent_docs, response: { "numFound" => parent_docs.size }, total_pages: 1) }

    context('when parent_collections is nil') do
      before do
        allow(presenter).to receive(:parent_collections).and_return(nil)
      end

      it { is_expected.to eq 0 }
    end

    context('when parent_collections is has no collections') do
      let(:parent_docs) { [] }

      it { is_expected.to eq 0 }
    end

    context('when parent_collections is has collections') do
      let(:collection1) { build(:collection_lw, title: ['col1']) }
      let(:collection2) { build(:collection_lw, title: ['col2']) }
      let!(:parent_docs) { [collection1, collection2] }

      before do
        presenter.parent_collections = parent_collections
      end

      it { is_expected.to eq 2 }
    end
  end

  describe "#collection_type_badge" do
    let(:collection_type) { create(:collection_type) }
    before do
      allow(collection_type).to receive(:badge_color).and_return("#ffa510")
      allow(presenter).to receive(:collection_type).and_return(collection_type)
    end

    subject { presenter.collection_type_badge }

    # it { is_expected.to eq "<span class=\"label\" style=\"background-color: #ffa510;\">" + collection_type.title + "</span>" }
    it { is_expected.to eq "<span class=\"label\" style=\"background-color: pink;\">" + collection_type.title + "</span>" } # TODO: fix
  end

  describe "#user_can_nest_collection?" do
    before do
      allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(true)
    end

    subject { presenter.user_can_nest_collection? }

    it { is_expected.to eq true }
  end

  describe "#user_can_create_new_nest_collection?" do
    let(:collection_type) { Hyrax::CollectionType.find_by_gid(collection.collection_type_gid.to_s) }

    before do
      allow(ability).to receive(:can?).with(:create_collection_of_type, collection_type).and_return(true)
    end

    it { expect(presenter.user_can_create_new_nest_collection?).to eq true }
  end

  describe '#show_path' do
    subject { presenter.show_path }

    it { is_expected.to eq "/dashboard/collections/#{solr_doc.id}?locale=en" }
  end

  describe "banner_file" do
    let(:solr_doc) { SolrDocument.new(id: '123') }

    let(:banner_info) do
      CollectionBrandingInfo.create(
        collection_id: "123",
        filename: "banner.gif",
        role: "banner",
        target_url: ""
      )
    end

    let(:logo_info) do
      CollectionBrandingInfo.create(
        collection_id: "123",
        filename: "logo.gif",
        role: "logo",
        alt_txt: "This is the logo",
        target_url: "http://logo.com"
      )
    end

    before do
      # allow(presenter).to receive(:id).and_return('123')
      allow(CollectionBrandingInfo).to receive(:where).with(collection_id: '123', role: 'banner').and_return([banner_info])
      allow(banner_info).to receive(:local_path).and_return("/temp/public/branding/123/banner/banner.gif")
      allow(CollectionBrandingInfo).to receive(:where).with(collection_id: '123', role: 'logo').and_return([logo_info])
      allow(logo_info).to receive(:local_path).and_return("/temp/public/branding/123/logo/logo.gif")
    end

    it "banner check", skip: true do
      tempfile = Tempfile.new('my_file')
      banner_info.save(tempfile.path)
      expect(presenter.banner_file).to eq("/branding/123/banner/banner.gif")
    end

    it "logo check", skip: true do
      tempfile = Tempfile.new('my_file')
      logo_info.save(tempfile.path)
      expect(presenter.logo_record).to eq([{ file: "logo.gif", file_location: "/branding/123/logo/logo.gif", alttext: "This is the logo", linkurl: "http://logo.com" }])
    end
  end

  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:based_near).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:date_created).to(:solr_document) }

  describe '#managed_access' do
    context 'when manager' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(true)
      end
      it 'returns Manage label' do
        expect(presenter.managed_access).to eq 'Manage'
      end
    end

    context 'when depositor' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(false)
        allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(true)
      end
      it 'returns Deposit label' do
        expect(presenter.managed_access).to eq 'Deposit'
      end
    end

    context 'when viewer' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(false)
        allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(false)
        allow(ability).to receive(:can?).with(:read, solr_doc).and_return(true)
      end
      it 'returns View label' do
        expect(presenter.managed_access).to eq 'View'
      end
    end
  end

  describe '#allow_batch?' do
    context 'when user cannot edit' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(false)
      end

      it 'returns false' do
        expect(presenter.allow_batch?).to be false
      end
    end

    context 'when user can edit' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(true)
      end

      it 'returns false' do
        expect(presenter.allow_batch?).to be true
      end
    end
  end
end
