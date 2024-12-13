# frozen_string_literal: true
# Updated: hyrax5
require 'rails_helper'

RSpec.describe ::Deepblue::ProvenancePath do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.provenance_path_debug_verbose ).to eq debug_verbose }
  end

  let(:id) { '123456789' }
  let(:data_set) { build( :data_set, id: id ) }
  let(:destination_name) { 'provenance' }
  let(:partial_path) { 'tmp/derivatives/12/34/56/78/9-' }
  let(:partial_path_log) { 'tmp/derivatives/12/34/56/78/9-provenance.log' }

  describe '#path_for_reference', :clean_db do
    context 'with data set' do
      it { expect( described_class.path_for_reference( data_set ).end_with?( partial_path_log ) ).to eq true }
    end
    context 'with string id' do
      it { expect( described_class.path_for_reference( id ).end_with?( partial_path_log ) ).to eq true }
    end
  end

  describe 'initalized with data set', :clean_db do
    context 'no destination name' do
      let(:prov_path) { described_class.new( data_set ) }
      it { expect( prov_path.id ).to eq id }
      it { expect( prov_path.destination_name ).to eq nil }
      it { expect( prov_path.provenance_path.end_with?( partial_path ) ).to eq true }
    end
    context 'with destination name' do
      let(:prov_path) { described_class.new( data_set, destination_name ) }
      it { expect( prov_path.id ).to eq id }
      it { expect( prov_path.destination_name ).to eq destination_name }
      it { expect( prov_path.provenance_path.end_with?( partial_path_log ) ).to eq true }
    end
  end

  describe 'initalized with string id', :clean_db do
    context 'no destination name' do
      let(:prov_path) { described_class.new( id ) }
      it { expect( prov_path.id ).to eq id }
      it { expect( prov_path.destination_name ).to eq nil }
      it { expect( prov_path.provenance_path.end_with?( partial_path ) ).to eq true }
    end
    context 'with destination name' do
      let(:prov_path) { described_class.new( id, destination_name ) }
      it { expect( prov_path.id ).to eq id }
      it { expect( prov_path.destination_name ).to eq destination_name }
      it { expect( prov_path.provenance_path.end_with?( partial_path_log ) ).to eq true }
    end
  end

end
