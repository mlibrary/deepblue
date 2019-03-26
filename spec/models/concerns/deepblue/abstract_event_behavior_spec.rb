# frozen_string_literal: true

class CurationConcernMock
  include ::Deepblue::AbstractEventBehavior
end

RSpec.describe Deepblue::AbstractEventBehavior do

  let( :event ) { 'the_event' }
  let( :id ) { 'id1234' }
  let( :behavior ) { 'some_behavior' }
  let( :key ) { "#{id}.#{event}" }
  let( :key_with_behavior ) { "#{id}.#{event}.#{behavior}" }
  let( :cache_value ) { 'the cache value ' }

  describe 'constants' do
    it do
      expect( Deepblue::AbstractEventBehavior::EVENT_CHARACTERIZE ).to eq 'characterize'
      expect( Deepblue::AbstractEventBehavior::EVENT_CHILD_ADD ).to eq 'child_add'
      expect( Deepblue::AbstractEventBehavior::EVENT_CHILD_REMOVE ).to eq 'child_remove'
      expect( Deepblue::AbstractEventBehavior::EVENT_CREATE ).to eq 'create'
      expect( Deepblue::AbstractEventBehavior::EVENT_CREATE_DERIVATIVE ).to eq 'create_derivative'
      expect( Deepblue::AbstractEventBehavior::EVENT_DESTROY ).to eq 'destroy'
      expect( Deepblue::AbstractEventBehavior::EVENT_DOWNLOAD ).to eq 'download'
      expect( Deepblue::AbstractEventBehavior::EVENT_FIXITY_CHECK ).to eq 'fixity_check'
      expect( Deepblue::AbstractEventBehavior::EVENT_GLOBUS ).to eq 'globus'
      expect( Deepblue::AbstractEventBehavior::EVENT_INGEST ).to eq 'ingest'
      expect( Deepblue::AbstractEventBehavior::EVENT_MIGRATE ).to eq 'migrate'
      expect( Deepblue::AbstractEventBehavior::EVENT_MINT_DOI ).to eq 'mint_doi'
      expect( Deepblue::AbstractEventBehavior::EVENT_PUBLISH ).to eq 'publish'
      expect( Deepblue::AbstractEventBehavior::EVENT_TOMBSTONE ).to eq 'tombstone'
      expect( Deepblue::AbstractEventBehavior::EVENT_UNPUBLISH ).to eq 'unpublish'
      expect( Deepblue::AbstractEventBehavior::EVENT_UPDATE ).to eq 'update'
      expect( Deepblue::AbstractEventBehavior::EVENT_UPDATE_AFTER ).to eq 'update_after'
      expect( Deepblue::AbstractEventBehavior::EVENT_UPDATE_BEFORE ).to eq 'update_before'
      expect( Deepblue::AbstractEventBehavior::EVENT_UPDATE_VERSION ).to eq 'update_version'
      expect( Deepblue::AbstractEventBehavior::EVENT_UPLOAD ).to eq 'upload'
      expect( Deepblue::AbstractEventBehavior::EVENT_VIRUS_SCAN ).to eq 'virus_scan'
      expect( Deepblue::AbstractEventBehavior::EVENT_WORKFLOW ).to eq 'workflow'
      expect( Deepblue::AbstractEventBehavior::EVENTS ).to eq [
        Deepblue::AbstractEventBehavior::EVENT_CHARACTERIZE,
        Deepblue::AbstractEventBehavior::EVENT_CHILD_ADD,
        Deepblue::AbstractEventBehavior::EVENT_CHILD_REMOVE,
        Deepblue::AbstractEventBehavior::EVENT_CREATE,
        Deepblue::AbstractEventBehavior::EVENT_CREATE_DERIVATIVE,
        Deepblue::AbstractEventBehavior::EVENT_DESTROY,
        Deepblue::AbstractEventBehavior::EVENT_DOWNLOAD,
        Deepblue::AbstractEventBehavior::EVENT_FIXITY_CHECK,
        Deepblue::AbstractEventBehavior::EVENT_GLOBUS,
        Deepblue::AbstractEventBehavior::EVENT_INGEST,
        Deepblue::AbstractEventBehavior::EVENT_MIGRATE,
        Deepblue::AbstractEventBehavior::EVENT_MINT_DOI,
        Deepblue::AbstractEventBehavior::EVENT_PUBLISH,
        Deepblue::AbstractEventBehavior::EVENT_TOMBSTONE,
        Deepblue::AbstractEventBehavior::EVENT_UNPUBLISH,
        Deepblue::AbstractEventBehavior::EVENT_UPDATE,
        Deepblue::AbstractEventBehavior::EVENT_UPDATE_AFTER,
        Deepblue::AbstractEventBehavior::EVENT_UPDATE_BEFORE,
        Deepblue::AbstractEventBehavior::EVENT_UPDATE_VERSION,
        Deepblue::AbstractEventBehavior::EVENT_UPLOAD,
        Deepblue::AbstractEventBehavior::EVENT_VIRUS_SCAN,
        Deepblue::AbstractEventBehavior::EVENT_WORKFLOW
      ]
      expect( Deepblue::AbstractEventBehavior::IGNORE_BLANK_KEY_VALUES ).to eq true
      expect( Deepblue::AbstractEventBehavior::USE_BLANK_KEY_VALUES ).to eq false
    end
  end

  describe '.event_attributes_cache_exist?' do
    subject { CurationConcernMock.new }
    context 'with behavior' do
      before do
        allow( Rails.cache ).to receive( :exist? ).with( key_with_behavior ).and_return true
      end
      it do
        expect( subject.event_attributes_cache_exist?( event: event, id: id, behavior: behavior ) ).to eq true
      end
    end
    context 'without behavior' do
      before do
        allow( Rails.cache ).to receive( :exist? ).with( key ).and_return true
      end
      it do
        expect( subject.event_attributes_cache_exist?( event: event, id: id ) ).to eq true
      end
    end
  end

  describe '.event_attributes_cache_fetch' do
    subject { CurationConcernMock.new }
    context 'with behavior' do
      before do
        allow( Rails.cache ).to receive( :fetch ).with( key_with_behavior ).and_return cache_value
      end
      it do
        expect( subject.event_attributes_cache_fetch( event: event, id: id, behavior: behavior ) ).to eq cache_value
      end
    end
    context 'without behavior' do
      let( :key ) { "#{id}.#{event}" }
      before do
        allow( Rails.cache ).to receive( :fetch ).with( key ).and_return cache_value
      end
      it do
        expect( subject.event_attributes_cache_fetch( event: event, id: id ) ).to eq cache_value
      end
    end
  end

  describe '.event_attributes_cache_key' do
    subject { CurationConcernMock.new }
    context 'with behavior' do
      let( :result ) { key_with_behavior }
      it do
        expect( subject.event_attributes_cache_key( event: event, id: id, behavior: behavior ) ).to eq result
      end
    end
    context 'without behavior' do
      let( :result ) { key }
      it do
        expect( subject.event_attributes_cache_key( event: event, id: id, behavior: nil ) ).to eq result
        expect( subject.event_attributes_cache_key( event: event, id: id, behavior: '' ) ).to eq result
        expect( subject.event_attributes_cache_key( event: event, id: id ) ).to eq result
      end
    end
  end

  describe '.event_attributes_cache_write' do
    subject { CurationConcernMock.new }
    context 'with behavior' do
      before do
        allow( Rails.cache ).to receive( :write ).with( key_with_behavior, cache_value )
      end
      it do
        subject.event_attributes_cache_write( event: event, id: id, attributes: cache_value, behavior: behavior )
      end
    end
    context 'without behavior' do
      let( :key ) { "#{id}.#{event}" }
      before do
        allow( Rails.cache ).to receive( :write ).with( key, cache_value )
      end
      it do
        subject.event_attributes_cache_write( event: event, id: id, attributes: cache_value )
      end
    end
  end

end
