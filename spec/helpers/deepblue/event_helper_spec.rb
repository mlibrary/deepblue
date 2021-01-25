# frozen_string_literal: true

require 'rails_helper'

class CurationConcernMock

end

class CurationConcernWithProvLoggingMock
  include ::Deepblue::ProvenanceBehavior
end

RSpec.describe Deepblue::EventHelper, type: :helper do

  let( :user ) { 'user@umich.edu' }

  describe '.after_batch_create_failure_callback' do
    let( :event_name ) { 'after_batch_create_failure' }
    let( :arrow_line ) { ">>>>> #{event_name} >>>>>" }
    before do
      allow( Rails.logger ).to receive( :debug ).with( any_args )
    end
    it do
      Deepblue::EventHelper.after_batch_create_failure_callback( user: user )
      expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 4 ).times
      expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user}" )
      expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
    end
  end

  describe '.after_batch_create_success_callback' do
    let( :event_name ) { 'after_batch_create_success' }
    let( :arrow_line ) { ">>>>> #{event_name} >>>>>" }
    before do
      allow( Rails.logger ).to receive( :debug ).with( any_args )
    end
    it do
      Deepblue::EventHelper.after_batch_create_success_callback( user: user )
      expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 4 ).times
      expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user}" )
      expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
    end
  end

  describe '.after_create_concern_callback' do
    let( :event_name ) { 'after_create_concern' }
    let( :arrow_line ) { ">>>>> #{event_name} >>>>>" }
    context 'curation_concern concern responds to provenance_create' do
      let( :curation_concern ) { CurationConcernWithProvLoggingMock.new }
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
        allow( curation_concern ).to receive( :provenance_create ).with( current_user: user, event_note: event_name )
      end
      it do
        Deepblue::EventHelper.after_create_concern_callback( curation_concern: curation_concern, user: user )
        expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 4 ).times
        expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user} >>>>> #{curation_concern}" )
        expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
      end
    end
    context 'curation_concern concern does not respond to provenance_create' do
      let( :curation_concern ) { CurationConcernMock.new }
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
      end
      it do
        Deepblue::EventHelper.after_create_concern_callback( curation_concern: curation_concern, user: user )
        expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 4 ).times
        expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user} >>>>> #{curation_concern}" )
        expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
      end
    end
  end

  describe '.after_create_fileset_callback' do
    let( :event_name ) { 'after_create_fileset' }
    let( :arrow_line ) { ">>>>> #{event_name} >>>>>" }
    context 'file_set responds to provenance_create' do
      let( :file_set ) { CurationConcernWithProvLoggingMock.new }
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
        allow( file_set ).to receive( :provenance_create ).with( current_user: user, event_note: event_name )
      end
      it do
        Deepblue::EventHelper.after_create_fileset_callback( file_set: file_set, user: user )
        expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 4 ).times
        expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user} >>>>> #{file_set}" )
        expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
      end
    end
    context 'file_set does not respond to provenance_create' do
      let( :file_set ) { CurationConcernMock.new }
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
      end
      it do
        Deepblue::EventHelper.after_create_fileset_callback( file_set: file_set, user: user )
        expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 4 ).times
        expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user} >>>>> #{file_set}" )
        expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
      end
    end
  end

end
