# frozen_string_literal: true

require 'rails_helper'

require_relative '../../../app/services/willow_sword/integration_service'

RSpec.describe ::WillowSword::IntegrationService do

  describe 'module debug verbose variables' do
    let(:debug_verbose) { false }
    it { expect( described_class.willow_sword_integration_service_debug_verbose ).to eq debug_verbose }
  end

  describe 'class variables' do
    it { expect( described_class.default_collection_title ).to eq 'SWORD Default Collection' }
  end

  describe '#default_collection_id' do

    context 'default_collection_id_cache is nil' do
      let(:title) { described_class.default_collection_title }
      let(:collection) { create(:collection_lw) }
      let(:solr_query) { "+generic_type_sim:Collection AND +title_tesim:#{title}" }

      before do
        expect(::ActiveFedora::SolrService).to receive(:query).with(solr_query, rows: 10).and_return [collection]
      end

      it 'performs a solr query' do
        described_class.default_collection_id_cache = nil
        expect( described_class.default_collection_id ).to eq collection.id
      end
    end

    context 'default_collection_id_cache is not nil' do
      let(:cached_id) { 'cached id' }

      before do
        expect(::ActiveFedora::SolrService).to_not receive(:query)
      end

      it 'performs a solr query' do
        described_class.default_collection_id_cache = cached_id
        expect( described_class.default_collection_id ).to eq cached_id
      end
    end

  end

end
