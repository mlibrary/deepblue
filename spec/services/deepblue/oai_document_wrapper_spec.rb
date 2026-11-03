# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::OaiDocumentWrapper do

  let(:document_model)    { double('DocumentModel', timestamp_key: 'timestamp') }
  let(:blacklight_config) { double('BlacklightConfig', document_model: document_model) }
  let(:controller)        { double('Controller', blacklight_config: blacklight_config) }
  let(:set_model) do
    Class.new do
      def self.controller=(_val); end
      def self.fields=(_val); end
    end
  end
  let(:search_service) { double('SearchService') }

  subject do
    described_class.new( controller,
                         record_local_prefix: 'data/',
                         record_prefix_legacy: 'oai:deepbluedata',
                         set_model: set_model,
                         limit: 50 ).tap do |wrapper|
      allow( wrapper ).to receive( :search_service ).and_return( search_service )
    end
  end

  def solr_doc( id )
    double( "SolrDocument(#{id})", id: id )
  end

  describe '#record_local_prefix' do
    it 'captures the configured local prefix' do
      expect( subject.record_local_prefix ).to eq 'data/'
    end
  end

  describe '#find for a single record' do
    let(:builder)  { double('SearchBuilder') }
    let(:query)    { double('Query') }
    let(:response) { double('Response', documents: [solr_doc('9s1616317')]) }

    before do
      allow( search_service ).to receive( :search_builder ).and_return( builder )
      allow( builder ).to receive( :where ).and_return( builder )
      allow( builder ).to receive( :query ).and_return( query )
      allow( search_service ).to receive( :repository ).and_return( double( search: response ) )
    end

    it 'strips the local prefix before querying Solr' do
      subject.find( 'data/9s1616317', metadata_prefix: 'oai_dc' )
      expect( builder ).to have_received( :where ).with( id: '9s1616317' )
    end

    it 'accepts the legacy oai:deepbluedata:<id> identifier form' do
      record = subject.find( 'oai:deepbluedata:9s1616317', metadata_prefix: 'oai_dc' )
      expect( builder ).to have_received( :where ).with( id: '9s1616317' )
      expect( record ).to be_a( ::Deepblue::OaiRecord )
      expect( record.id ).to eq 'data/9s1616317'
    end

    it 'decorates the returned record with the prefixed id' do
      record = subject.find( 'data/9s1616317', metadata_prefix: 'oai_dc' )
      expect( record ).to be_a( ::Deepblue::OaiRecord )
      expect( record.id ).to eq 'data/9s1616317'
    end

    context 'when the record is not found' do
      let(:response) { double('Response', documents: []) }

      it 'returns nil' do
        expect( subject.find( 'data/missing', metadata_prefix: 'oai_dc' ) ).to be_nil
      end
    end

    context 'when the identifier lacks the local prefix' do
      it 'raises an OAI id error without querying Solr' do
        expect { subject.find( '9s1616317', metadata_prefix: 'oai_dc' ) }
          .to raise_error( OAI::IdException )
        expect( search_service ).not_to have_received( :repository )
      end
    end
  end

  describe '#find for :all' do
    let(:builder)  { double('SearchBuilder', merge: nil, query: double('Query')) }
    let(:response) { double('Response', total: 1, documents: [solr_doc('abc'), solr_doc('def')]) }

    before do
      allow( search_service ).to receive( :search_builder ).and_return( builder )
      allow( builder ).to receive( :merge ).and_return( builder )
      allow( search_service ).to receive( :repository ).and_return( double( search: response ) )
    end

    it 'decorates every document' do
      records = subject.find( :all, {} )
      expect( records ).to all( be_a( ::Deepblue::OaiRecord ) )
      expect( records.map( &:id ) ).to eq ['data/abc', 'data/def']
    end
  end

  describe '#decorate_result (private)' do
    let(:doc) { solr_doc('abc') }

    it 'decorates an array of documents' do
      result = subject.send( :decorate_result, [doc] )
      expect( result.map( &:id ) ).to eq ['data/abc']
    end

    it 'preserves a PartialResult token while decorating its records' do
      token  = double('ResumptionToken')
      result = subject.send( :decorate_result,
                             OAI::Provider::PartialResult.new( [doc], token ) )
      expect( result ).to be_a( OAI::Provider::PartialResult )
      expect( result.token ).to be( token )
      expect( result.records.map( &:id ) ).to eq ['data/abc']
    end

    it 'passes nil through unchanged' do
      expect( subject.send( :decorate_result, nil ) ).to be_nil
    end
  end

end
