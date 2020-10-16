# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobStatus, type: :model do

  let( :job_id )     { 'job-id-4321' }
  let( :job_class )  { 'JobClassDummy'}
  # let( :job_status ) { described_class.new( job_id: job_id, job_class: job_class ) }
  let( :finished )   { JobStatus::FINISHED }
  let( :started )    { JobStatus::STARTED }

  describe 'verifying factories' do

    describe ':job_status' do
      let( :job_status ) { build( :job_status ) }

      it 'will, by default, have no status' do
        expect( job_status.status ).to eq( nil )
      end
    end

  end

  describe 'properties' do

    it 'has expected properties' do
      expect( subject ).to respond_to( :job_class )
      expect( subject ).to respond_to( :job_id )
      expect( subject ).to respond_to( :parent_job_id )
      expect( subject ).to respond_to( :status )
      expect( subject ).to respond_to( :state )
      expect( subject ).to respond_to( :message )
      expect( subject ).to respond_to( :error )
    end

  end

  describe '#finished?' do

    describe 'when status not specified' do
      before do
        subject.status = nil
      end
      it 'will be false' do
        expect( subject.finished? ).to eq( false )
      end
    end

    describe 'when status started' do
      before do
        subject.status = started
      end
      it 'will be false' do
        expect( subject.finished? ).to eq( false )
      end
    end

    describe 'when status finished' do
      before do
        subject.status = finished
      end
      it 'will be true' do
        expect( subject.finished? ).to eq( true )
      end
    end

  end

  describe '#started?' do

    describe 'when status not specified' do
      before do
        subject.status = nil
      end
      it 'will be false' do
        expect( subject.started? ).to eq( false )
      end
    end

    describe 'when status started' do
      before do
        subject.status = started
      end
      it 'will be true' do
        expect( subject.started? ).to eq( true )
      end
    end

    describe 'when status finished' do
      before do
        subject.status = finished
      end
      it 'will be false' do
        expect( subject.started? ).to eq( false )
      end
    end

  end

end
