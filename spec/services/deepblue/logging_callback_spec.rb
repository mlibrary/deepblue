# frozen_string_literal: true

RSpec.describe Deepblue::LoggingCallback do

  let( :event_name ) { 'the_event_name' }
  let( :event_line ) { ">>>>> #{event_name} >>>>>" }
  let( :msg ) { 'The message.' }
  let( :user ) { 'user@umich.edu' }

  describe '.process_event' do
    # subject { lambda { |event_name, msg| Deepblue::LoggingCallback.process_event( event_name: event_name, msg: msg ) } }

    before do
      allow( Rails.logger ).to receive( :debug ).with( any_args )
    end
    it do
      described_class.process_event( event_name: event_name, msg: msg )
      expect( Rails.logger ).to have_received( :debug ).with( event_line ).exactly( 4 ).times
      expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{msg}" )
      expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
    end
  end

  describe '.process_event_curation_concern' do
    let( :curation_concern ) { 'DataSet XYZ' }
    before do
      allow( Rails.logger ).to receive( :debug ).with( any_args )
    end
    it do
      described_class.process_event_curation_concern( event_name: event_name, curation_concern: curation_concern, user: user )
      expect( Rails.logger ).to have_received( :debug ).with( event_line ).exactly( 4 ).times
      expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user} >>>>> #{curation_concern}" )
      expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
    end
  end

  describe '.process_event_file_set' do
    let( :file_set ) { 'FileSet XYZ' }
    before do
      allow( Rails.logger ).to receive( :debug ).with( any_args )
    end
    it do
      described_class.process_event_file_set( event_name: event_name, file_set: file_set, user: user )
      expect( Rails.logger ).to have_received( :debug ).with( event_line ).exactly( 4 ).times
      expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user} >>>>> #{file_set}" )
      expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
    end
  end

  describe '.process_event_user' do
    context 'with msg' do
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
      end
      it do
        described_class.process_event_user( event_name: event_name, user: user, msg: msg )
        expect( Rails.logger ).to have_received( :debug ).with( event_line ).exactly( 4 ).times
        expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user} >>>>> #{msg}" )
        expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
      end
    end
    context 'without msg' do
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
      end
      it do
        described_class.process_event_user( event_name: event_name, user: user, msg: '' )
        described_class.process_event_user( event_name: event_name, user: user, msg: nil )
        expect( Rails.logger ).to have_received( :debug ).with( event_line ).exactly( 8 ).times
        expect( Rails.logger ).to have_received( :debug ).with( "#{event_name} >>>>> #{user}" ).twice
        expect( Rails.logger ).to have_received( :debug ).exactly( 10 ).times
      end
    end
  end

end
