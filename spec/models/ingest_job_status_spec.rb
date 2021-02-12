# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/jobs/ingest_job_status'

RSpec.describe IngestJobStatus do

  let( :job_id )     { 'job-id-4321' }
  let( :job_class )  { 'JobClassDummy'}
  let( :job_status ) { build( :job_status, job_id: job_id, job_class: job_class ) }
  let( :finished )   { JobStatus::FINISHED }
  let( :started )    { JobStatus::STARTED }
  let( :message1 )   { "Message One" }

  let( :ingest_job_status )       { described_class.new( job_status: job_status ) }
  let( :ordered_job_status_list ) { IngestJobStatus::ORDERED_JOB_STATUS_LIST }

  describe 'constants' do
    it 'has the right values' do
    expect( IngestJobStatus::CREATE_FILE_SET               ).to eq 'create_file_set'
    expect( IngestJobStatus::DELETE_FILE                   ).to eq 'delete_file'
    expect( IngestJobStatus::FINISHED_ADD_FILE_TO_FILE_SET ).to eq 'finished_add_file_to_file_set'
    expect( IngestJobStatus::FINISHED_ATTACH_FILE_TO_WORK  ).to eq 'finished_attach_file_to_work'
    expect( IngestJobStatus::FINISHED_CHARACTERIZE         ).to eq 'finished_characterize'
    expect( IngestJobStatus::FINISHED_CREATE_DERIVATIVES   ).to eq 'finished_create_derivatives'
    expect( IngestJobStatus::FINISHED_FILE_INGEST          ).to eq 'finished_file_ingest'
    expect( IngestJobStatus::FINISHED_NOTIFY               ).to eq 'finished_notify'
    expect( IngestJobStatus::FINISHED_LOG_STARTING         ).to eq 'finished_log_starting'
    expect( IngestJobStatus::FINISHED_VALIDATE_FILES       ).to eq 'finished_validate_files'
    expect( IngestJobStatus::FINISHED_VERSIONING_SERVICE_CREATE ).to eq 'finished_versioning_service_create'
    expect( IngestJobStatus::FINISHED_UPLOAD_FILES         ).to eq 'finished_upload_files'
    expect( IngestJobStatus::UPLOADING_FILES               ).to eq 'uploading_files'
    expect( IngestJobStatus::ORDERED_JOB_STATUS_LIST ).to eq [ IngestJobStatus::FINISHED_LOG_STARTING,
                                                              IngestJobStatus::FINISHED_VALIDATE_FILES,
                                                              IngestJobStatus::UPLOADING_FILES,
                                                              IngestJobStatus::FINISHED_ATTACH_FILE_TO_WORK,
                                                              IngestJobStatus::CREATE_FILE_SET,
                                                              IngestJobStatus::FINISHED_ADD_FILE_TO_FILE_SET,
                                                              IngestJobStatus::FINISHED_VERSIONING_SERVICE_CREATE,
                                                              IngestJobStatus::FINISHED_FILE_INGEST,
                                                              IngestJobStatus::FINISHED_CHARACTERIZE,
                                                              IngestJobStatus::FINISHED_CREATE_DERIVATIVES,
                                                              IngestJobStatus::DELETE_FILE,
                                                              IngestJobStatus::FINISHED_UPLOAD_FILES,
                                                              IngestJobStatus::FINISHED_NOTIFY ]

    expect( IngestJobStatus::UPLOADING_FILES_STATUS_LIST ).to eq [ IngestJobStatus::UPLOADING_FILES,
                                                              IngestJobStatus::CREATE_FILE_SET,
                                                              IngestJobStatus::FINISHED_ADD_FILE_TO_FILE_SET,
                                                              IngestJobStatus::FINISHED_VERSIONING_SERVICE_CREATE,
                                                              IngestJobStatus::FINISHED_FILE_INGEST,
                                                              IngestJobStatus::FINISHED_CHARACTERIZE,
                                                              IngestJobStatus::FINISHED_CREATE_DERIVATIVES,
                                                              IngestJobStatus::DELETE_FILE ]
    end
  end

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
  it { is_expected.to delegate_method( :main_cc_id        ).to( :job_status ) }
  it { is_expected.to delegate_method( :message           ).to( :job_status ) }
  it { is_expected.to delegate_method( :null_job_status?  ).to( :job_status ) }
  it { is_expected.to delegate_method( :parent_job_id     ).to( :job_status ) }
  it { is_expected.to delegate_method( :save!             ).to( :job_status ) }
  it { is_expected.to delegate_method( :started?          ).to( :job_status ) }
  it { is_expected.to delegate_method( :state             ).to( :job_status ) }
  it { is_expected.to delegate_method( :state_deserialize ).to( :job_status ) }
  it { is_expected.to delegate_method( :state_serialize   ).to( :job_status ) }
  it { is_expected.to delegate_method( :state_serialize!  ).to( :job_status ) }
  it { is_expected.to delegate_method( :status            ).to( :job_status ) }
  it { is_expected.to delegate_method( :status?           ).to( :job_status ) }
  it { is_expected.to delegate_method( :user_id           ).to( :job_status ) }

  describe 'started is before every member of job status list', skip: true do

  end

  describe 'finished is after every member of job status list', skip: true do

  end

  describe '#find_job_status', skip: true do

  end

  describe '#find_or_create_job_started', skip: true do

  end

  describe '.initialize' do

    context 'with a job' do
      let( :job ) { TestJob.send( :job_or_instantiate ) }
      it "initializes" do
        job_status_var = nil
        expect { job_status_var = JobStatus.find_or_create_job_started( job: job ) }.to change { JobStatus.count }.by 1
        expect( job_status_var.null_job_status? ).to eq false
        ingest_job_status = nil
        expect { ingest_job_status = IngestJobStatus.new( job: job ) }.to change { JobStatus.count }.by 0
        expect( ingest_job_status ).not_to eq nil
        # expect( job_status_var.job_status.class.name ).to eq JobStatus::Null.class.name
        expect( ingest_job_status.job_id ).to eq job.job_id
      end
    end

    context 'with no job' do
      let( :job ) { nil }
      it "initializes" do
        ingest_job_status = nil
        expect { ingest_job_status = IngestJobStatus.new( job: job ) }.to change { JobStatus.count }.by 0
        expect( ingest_job_status ).not_to eq nil
        expect( ingest_job_status.job_status.null_job_status? ).to eq true
        expect( ingest_job_status.job_id ).to eq nil
      end
    end

  end

  describe '#new_job_status' do
    let( :job ) { TestJob.send( :job_or_instantiate ) }
    let( :job_id ) { job.job_id }

    context 'create a new ingest job status' do
      it "creates it" do
        job_status_var = nil
        expect { job_status_var = JobStatus.find_or_create_job_started( job: job ) }.to change { JobStatus.count }.by 1
        expect( job_status_var.null_job_status? ).to eq false
        ingest_job_status = nil
        expect { ingest_job_status = IngestJobStatus.new_job_status( job_id: job_id ) }.to change { JobStatus.count }.by( 0 )
        expect( ingest_job_status ).not_to eq nil
        expect( ingest_job_status.job_status.null_job_status? ).to eq false
        expect( ingest_job_status.job_id ).to eq job_id
      end
    end

    context 'create a new ingest job status with no job specified' do
      let( :job_id ) { nil }
      it "it creates it" do
        ingest_job_status = nil
        expect { ingest_job_status = IngestJobStatus.new_job_status( job_id: job_id ) }.to change { JobStatus.count }.by 0
        expect( ingest_job_status ).not_to eq nil
        expect( ingest_job_status.job_status.null_job_status? ).to eq true
        expect( ingest_job_status.job_id ).to eq nil
      end
    end

  end

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

  describe 'default ingest job status' do
    it "has a null job status" do
      expect( subject.null_job_status? ).to eq true
    end
  end

  describe '.did_verbose' do
    it "is TODO" do
      skip "add tests"
    end
  end

  describe '.finished!' do
    let(:expected_status) { finished }
    let( :job ) { TestJob.send( :job_or_instantiate ) }
    let( :job_id ) { job.job_id }
    let(:job_status_var) { JobStatus.create( job_id: job_id, job_class: job.class ) }
    let(:ingest_job_status) { IngestJobStatus.new( job_status: job_status_var ) }

    before do
      # job_status_var = nil
      # ingest_job_status = nil
      # expect { job_status_var = JobStatus.create( job_id: job_id, job_class: job.class ) }.to change { JobStatus.count }.by 1
      # expect { ingest_job_status = IngestJobStatus.new( job_status: job_status_var ) }.to change { JobStatus.count }.by 0
      expect(job_status_var.null_job_status?).to eq false
      expect(ingest_job_status.job_status).to eq job_status_var
    end

    it "finished with no message" do
      ingest_job_status.verbose = false
      expect( ingest_job_status.null_job_status? ).to eq false
      expect( ingest_job_status.verbose ).to eq false
      expect( ingest_job_status.message ).to eq nil
      expect( ingest_job_status.status ).to_not eq expected_status
      expect{ ingest_job_status.finished! }.to change { JobStatus.count }.by 0
      ingest_job_status.reload
      expect( ingest_job_status.status ).to eq expected_status
      expect( ingest_job_status.message ).to eq nil
    end
    it "finished with message and not verbose" do
      ingest_job_status.verbose = false
      expect( ingest_job_status.null_job_status? ).to eq false
      expect( ingest_job_status.verbose ).to eq false
      expect( ingest_job_status.message ).to eq nil
      expect( ingest_job_status.status ).to_not eq expected_status
      expect{ ingest_job_status.finished!( message: message1 ) }.to change {  JobStatus.count }.by 0
      ingest_job_status.reload
      expect( ingest_job_status.status ).to eq expected_status
      expect( ingest_job_status.message ).to eq message1
    end
    it "finished with message and verbose" do
      ingest_job_status.verbose = true
      expect( ingest_job_status.null_job_status? ).to eq false
      expect( ingest_job_status.verbose ).to eq true
      expect( ingest_job_status.message ).to eq nil
      expect( ingest_job_status.status ).to_not eq expected_status
      expect{ ingest_job_status.finished!( message: message1 ) }.to change {  JobStatus.count }.by 0
      ingest_job_status.reload
      expect( ingest_job_status.status ).to eq expected_status
      expect( ingest_job_status.message ).to eq "#{message1}\nstatus changed to: finished"
    end
  end

  describe '.started!' do
    it "status updated" do
      skip "add tests"
    end
    it "status and message updated when verbose" do
      skip "add tests"
    end
  end

  describe '.status!' do
    it "is TODO" do
      skip "add tests"
    end
  end

end
