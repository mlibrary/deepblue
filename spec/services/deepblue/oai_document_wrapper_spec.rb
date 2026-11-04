# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::OaiDocumentWrapper do

  let(:document_model)    { double( 'document_model', timestamp_key: 'timestamp' ) }
  let(:blacklight_config) { double( 'blacklight_config', document_model: document_model ) }
  let(:controller)        { double( 'controller', blacklight_config: blacklight_config ) }
  let(:options)           { { record_prefix_legacy: 'oai:deepbluedata' } }

  subject( :wrapper ) { described_class.new( controller, options ) }

  describe '#initialize' do
    it 'captures the legacy record prefix' do
      expect( wrapper.record_prefix_legacy ).to eq 'oai:deepbluedata'
    end

    it 'defaults the legacy prefix to an empty string when not provided' do
      expect( described_class.new( controller, {} ).record_prefix_legacy ).to eq ''
    end
  end

  describe '#find' do
    let(:captured) { [] }

    before do
      allow_any_instance_of( BlacklightOaiProvider::SolrDocumentWrapper ).to receive( :find ) do |_instance, selector, _opts|
        captured << selector
        :result
      end
    end

    it 'strips a legacy oai:deepbluedata: prefix before lookup' do
      wrapper.find( 'oai:deepbluedata:ht24wj40p' )
      expect( captured ).to eq [ 'ht24wj40p' ]
    end

    it 'leaves a bare id unchanged' do
      wrapper.find( 'ht24wj40p' )
      expect( captured ).to eq [ 'ht24wj40p' ]
    end

    it 'leaves a non-legacy prefixed id unchanged' do
      wrapper.find( 'oai:data.deepblue.lib.umich.edu:ht24wj40p' )
      expect( captured ).to eq [ 'oai:data.deepblue.lib.umich.edu:ht24wj40p' ]
    end

    it 'passes :all through unchanged' do
      wrapper.find( :all )
      expect( captured ).to eq [ :all ]
    end

    it 'does not strip when a resumption token is present' do
      wrapper.find( 'oai:deepbluedata:ht24wj40p', resumption_token: 'token' )
      expect( captured ).to eq [ 'oai:deepbluedata:ht24wj40p' ]
    end
  end

end
