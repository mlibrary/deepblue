# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::OaiRecord do

  let(:document) { double('SolrDocument', id: '9s1616317') }

  subject { described_class.new( document, 'data/' ) }

  describe '#id' do
    it 'prepends the local prefix to the wrapped document id' do
      expect( subject.id ).to eq 'data/9s1616317'
    end

    context 'with a blank prefix' do
      subject { described_class.new( document, '' ) }

      it 'returns the wrapped document id unchanged' do
        expect( subject.id ).to eq '9s1616317'
      end
    end
  end

  describe 'delegation' do
    let(:document) { double('SolrDocument', id: '9s1616317', to_oai_dc: '<dc/>', sets: [:a]) }

    it 'delegates other methods to the wrapped document' do
      expect( subject.to_oai_dc ).to eq '<dc/>'
      expect( subject.sets ).to eq [:a]
    end

    it 'reports the wrapped document via __getobj__' do
      expect( subject.__getobj__ ).to be( document )
    end
  end

end
