# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/jobs/ingest_job_status'

RSpec.describe IngestJobStatus do

  let( :job_id )     { 'job-id-4321' }
  let( :job_class )  { 'JobClassDummy'}
  let( :job_status ) { build( :job_status, job_id: job_id, job_class: job_class ) }
  let( :finished )   { JobStatus::FINISHED }
  let( :started )    { JobStatus::STARTED }

  let( :ingest_job_status )       { described_class.new( job_status: job_status ) }
  let( :ordered_job_status_list ) { IngestJobStatus::ORDERED_JOB_STATUS_LIST }

  describe 'properties' do

    it 'has expected properties' do
      expect( subject ).to respond_to( :job_id )
      expect( subject ).to respond_to( :job_status )
      expect( subject ).to respond_to( :ordered_job_status_list )
    end

  end

  it { is_expected.to delegate_method( :add_message       ).to( :job_status ) }
  it { is_expected.to delegate_method( :add_message!      ).to( :job_status ) }
  it { is_expected.to delegate_method( :error             ).to( :job_status ) }
  it { is_expected.to delegate_method( :error!            ).to( :job_status ) }
  it { is_expected.to delegate_method( :finished?         ).to( :job_status ) }
  it { is_expected.to delegate_method( :job_class         ).to( :job_status ) }
  it { is_expected.to delegate_method( :parent_job_id     ).to( :job_status ) }
  it { is_expected.to delegate_method( :message           ).to( :job_status ) }
  it { is_expected.to delegate_method( :null_job_status?  ).to( :job_status ) }
  it { is_expected.to delegate_method( :save!             ).to( :job_status ) }
  it { is_expected.to delegate_method( :started?          ).to( :job_status ) }
  it { is_expected.to delegate_method( :state             ).to( :job_status ) }
  it { is_expected.to delegate_method( :state_deserialize ).to( :job_status ) }
  it { is_expected.to delegate_method( :state_serialize   ).to( :job_status ) }
  it { is_expected.to delegate_method( :state_serialize!  ).to( :job_status ) }
  it { is_expected.to delegate_method( :status            ).to( :job_status ) }
  it { is_expected.to delegate_method( :status?           ).to( :job_status ) }

  # describe 'started is before every member of job status list' do
  #
  # end
  #
  # describe 'finished is after every member of job status list' do
  #
  # end

  describe '#did?' do

    it 'is false for all if status is nil' do
      job_status.status = nil
      ordered_job_status_list.each do |test_status|
        expect( ingest_job_status.did? test_status ).to eq( false )
      end
    end

    it 'is false for all if status is started' do
      job_status.status = started
      ordered_job_status_list.each do |test_status|
        expect( ingest_job_status.did? test_status ).to eq( false )
      end
    end

    it 'is true for all if status is finished' do
      job_status.status = finished
      ordered_job_status_list.each do |test_status|
        expect( ingest_job_status.did? test_status ).to eq( true )
      end
    end

    it 'correctly orders every member of job status list' do
      ordered_job_status_list.each_with_index do |status1,index1|
        job_status.status = status1
        expect( ingest_job_status.did? nil ).to eq( false )
        expect( ingest_job_status.did? started ).to eq( true )
        expect( ingest_job_status.did? finished ).to eq( false )
        ordered_job_status_list.each_with_index do |status2,index2|
          if index2 <= index1
            expect( ingest_job_status.did? status2 ).to eq( true )
          else
            expect( ingest_job_status.did? status2 ).to eq( false )
          end
        end
      end
    end

  end

end
