# frozen_string_literal: true

require 'rails_helper'

require_relative "../../app/jobs/deepblue/deepblue_job"

RSpec.describe JobStatus, type: :model do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.job_status_debug_verbose ).to eq debug_verbose }
  end

  describe 'other module values' do
    it { expect( described_class::FINISHED ).to eq 'finished' }
    it { expect( described_class::STARTED  ).to eq 'started'  }
  end

  let( :job_id )     { 'job-id-4321' }
  let( :job_class )  { 'JobClassDummy'}
  # let( :job_status ) { described_class.new( job_id: job_id, job_class: job_class ) }
  let( :finished )   { JobStatus::FINISHED }
  let( :started )    { JobStatus::STARTED }

  describe 'verifying factories' do

    describe ':job_status' do
      let( :job_status ) { build( :job_status ) }

      it 'will, by default, have no status' do
        expect( job_status.null_job_status? ).to eq false
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

  describe '#find_or_create' do

    context 'for existing job status record' do
      let( :job ) { TestJob.send( :job_or_instantiate ) }
      it "finds an existing record" do
        expect { JobStatus.create( job_id: job.job_id, job_class: job.class ) }.to change { JobStatus.count }.by 1
        job_found = nil
        expect { job_found = JobStatus.find_or_create( job: job ) }.to_not change { JobStatus.count }
        expect( job_found.null_job_status? ).to eq false
        expect( job_found.job_id ).to eq job.job_id
        expect( job_found.job_class ).to eq job.class.name
      end
    end

    context 'for no job status record' do
      let( :job ) { TestJob.send( :job_or_instantiate ) }
      it "creates a record" do
        job_found = nil
        expect { job_found = JobStatus.find_or_create( job: job ) }.to change { JobStatus.count }.by 1
        expect( job_found.null_job_status? ).to eq false
        expect( job_found.job_id ).to eq job.job_id
        expect( job_found.job_class ).to eq job.class.name
      end
    end

  end

  describe '#find_or_create_job_error' do
    let( :error ) { 'Some horrendous apocalypse!'}

    context 'for existing job status record' do
      let( :job ) { TestJob.send( :job_or_instantiate ) }
      it "finds an existing record" do
        expect { JobStatus.create( job_id: job.job_id, job_class: job.class ) }.to change { JobStatus.count }.by 1
        job_found = nil
        expect { job_found = JobStatus.find_or_create_job_error( job: job, error: error ) }.to_not change { JobStatus.count }
        expect( job_found.null_job_status? ).to eq false
        expect( job_found.job_id ).to eq job.job_id
        expect( job_found.job_class ).to eq job.class.name
        expect( job_found.error ).to eq error
      end
    end

    context 'for no job status record' do
      let( :job ) { TestJob.send( :job_or_instantiate ) }
      it "creates a record" do
        job_found = nil
        expect { job_found = JobStatus.find_or_create_job_error( job: job, error: error ) }.to change { JobStatus.count }.by 1
        expect( job_found.null_job_status? ).to eq false
        expect( job_found.job_id ).to eq job.job_id
        expect( job_found.job_class ).to eq job.class.name
        expect( job_found.error ).to eq error
      end
    end

  end

  describe '#find_or_create_job_finished' do
    let( :status ) { JobStatus::FINISHED }

    context 'for existing job status record' do
      let( :job ) { TestJob.send( :job_or_instantiate ) }
      it "finds an existing record" do
        expect { JobStatus.create( job_id: job.job_id, job_class: job.class ) }.to change { JobStatus.count }.by 1
        job_found = nil
        expect { job_found = JobStatus.find_or_create_job_finished( job: job ) }.to_not change { JobStatus.count }
        expect( job_found.null_job_status? ).to eq false
        expect( job_found.job_id ).to eq job.job_id
        expect( job_found.job_class ).to eq job.class.name
        expect( job_found.status ).to eq status
      end
    end

    context 'for no job status record' do
      let( :job ) { TestJob.send( :job_or_instantiate ) }
      it "creates a record" do
        job_found = nil
        expect { job_found = JobStatus.find_or_create_job_finished( job: job ) }.to change { JobStatus.count }.by 1
        expect( job_found.null_job_status? ).to eq false
        expect( job_found.job_id ).to eq job.job_id
        expect( job_found.job_class ).to eq job.class.name
        expect( job_found.status ).to eq status
      end
    end

  end

  describe '#find_or_create_job_started' do
    let( :status ) { JobStatus::STARTED }

    context 'for existing job status record' do
      let( :job ) { TestJob.send( :job_or_instantiate ) }
      it "finds an existing record" do
        expect { JobStatus.create( job_id: job.job_id, job_class: job.class ) }.to change { JobStatus.count }.by 1
        job_found = nil
        expect{ job_found = JobStatus.find_or_create_job_started( job: job ) }.to_not change { JobStatus.count }
        expect( job_found.null_job_status? ).to eq false
        expect( job_found.job_id ).to eq job.job_id
        expect( job_found.job_class ).to eq job.class.name
        expect( job_found.status ).to eq status
      end
    end

    context 'for no job status record' do
      let( :job ) { TestJob.send( :job_or_instantiate ) }
      it "creates a record" do
        job_status = nil
        expect { job_status = JobStatus.find_or_create_job_started( job: job ) }.to change { JobStatus.count }.by 1
        expect( job_status.null_job_status? ).to eq false
        expect( job_status.job_id ).to eq job.job_id
        expect( job_status.job_class ).to eq job.class.name
        expect( job_status.status ).to eq status
      end
    end

  end

  describe '.finished?' do

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
        expect( subject.null_job_status? ).to eq false
        expect( subject.finished? ).to eq( false )
      end
    end

    describe 'when status finished' do
      before do
        subject.status = finished
      end
      it 'will be true' do
        expect( subject.null_job_status? ).to eq false
        expect( subject.finished? ).to eq( true )
      end
    end

    describe 'for existing job status record' do
      let( :status ) { JobStatus::FINISHED }

      context "finds an existing record when given the job" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
          expect { JobStatus.create( job_id: job.job_id,
                                     job_class: job.class,
                                     status: status ) }.to change { JobStatus.count }.by 1
          job_found = nil
          expect{ job_found = JobStatus.find_or_create( job: job ) }.to_not change { JobStatus.count }
          expect( JobStatus.finished?( job: job_found ) ).to eq true
        end
      end
      context "finds an existing record when given the job id" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
          expect { JobStatus.create( job_id: job.job_id,
                                     job_class: job.class,
                                     status: status ) }.to change { JobStatus.count }.by 1
          expect( JobStatus.finished?( job_id: job.job_id ) ).to eq true
        end
      end
    end

  end

  describe '.started?' do

    describe 'when status not specified' do
      before do
        subject.status = nil
      end
      it 'will be false' do
        expect( subject.null_job_status? ).to eq false
        expect( subject.started? ).to eq( false )
      end
    end

    describe 'when status started' do
      before do
        subject.status = started
      end
      it 'will be true' do
        expect( subject.null_job_status? ).to eq false
        expect( subject.started? ).to eq( true )
      end
    end

    describe 'when status finished' do
      before do
        subject.status = finished
      end
      it 'will be false' do
        expect( subject.null_job_status? ).to eq false
        expect( subject.started? ).to eq( false )
      end
    end

  end

  describe "#status?" do

    describe 'for existing job status record' do
      let( :status ) { "SomeJobStatus" }
      let( :non_existent_status ) { "NotToBeFound" }

      context "finds an existing record when given the job" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
          expect { JobStatus.create( job_id: job.job_id,
                                     job_class: job.class,
                                     status: status ) }.to change { JobStatus.count }.by 1
          expect( JobStatus.status?( job: job, status: status ) ).to eq true
          expect( JobStatus.status?( job: job, status: non_existent_status ) ).to eq false
        end
      end

      context "finds an existing record when given the job id" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
          expect { JobStatus.create( job_id: job.job_id,
                                     job_class: job.class,
                                     status: status ) }.to change { JobStatus.count }.by 1
          expect( JobStatus.status?( job_id: job.job_id, status: status ) ).to eq true
          expect( JobStatus.status?( job_id: job.job_id, status: non_existent_status ) ).to eq false
        end
      end
    end

  end

  describe "#update_status" do

    describe 'for existing job status record' do
      let( :old_status ) { "OldJobStatus" }
      let( :new_status ) { "NewJobStatus" }

      context "finds an existing record when given the job" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
            expect { JobStatus.create( job_id: job.job_id,
                                       job_class: job.class,
                                       status: old_status ) }.to change { JobStatus.count }.by 1
            JobStatus.update_status( job: job, status: new_status )
            expect( JobStatus.status?( job: job, status: old_status ) ).to eq false
            expect( JobStatus.status?( job: job, status: new_status ) ).to eq true
        end
      end

      context "finds an existing record when given the job id" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
          expect { JobStatus.create( job_id: job.job_id,
                                     job_class: job.class,
                                     status: old_status ) }.to change { JobStatus.count }.by 1
          JobStatus.update_status( job_id: job.job_id, status: new_status )
          expect( JobStatus.status?( job_id: job.job_id, status: old_status ) ).to eq false
          expect( JobStatus.status?( job_id: job.job_id, status: new_status ) ).to eq true
        end
      end
    end

  end

  describe "#update_status_finished" do

    describe 'for existing job status record' do
      let( :old_status ) { "OldJobStatus" }
      let( :new_status ) { JobStatus::FINISHED }

      context "finds an existing record when given the job" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
          expect { JobStatus.create( job_id: job.job_id,
                                     job_class: job.class,
                                     status: old_status ) }.to change { JobStatus.count }.by 1
          JobStatus.update_status_finished( job: job )
          expect( JobStatus.status?( job: job, status: old_status ) ).to eq false
          expect( JobStatus.status?( job: job, status: new_status ) ).to eq true
        end
      end

      context "finds an existing record when given the job id" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
          expect { JobStatus.create( job_id: job.job_id,
                                     job_class: job.class,
                                     status: old_status ) }.to change { JobStatus.count }.by 1
          JobStatus.update_status_finished( job_id: job.job_id )
          expect( JobStatus.status?( job_id: job.job_id, status: old_status ) ).to eq false
          expect( JobStatus.status?( job_id: job.job_id, status: new_status ) ).to eq true
        end
      end
    end

  end

  describe "#update_status_started" do

    describe 'for existing job status record' do
      let( :old_status ) { "OldJobStatus" }
      let( :new_status ) { JobStatus::STARTED }

      context "finds an existing record when given the job" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
          expect { JobStatus.create( job_id: job.job_id,
                                     job_class: job.class,
                                     status: old_status ) }.to change { JobStatus.count }.by 1
          JobStatus.update_status_started( job: job )
          expect( JobStatus.status?( job: job, status: old_status ) ).to eq false
          expect( JobStatus.status?( job: job, status: new_status ) ).to eq true
        end
      end

      context "finds an existing record when given the job id" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "finds it" do
          expect { JobStatus.create( job_id: job.job_id,
                                     job_class: job.class,
                                     status: old_status ) }.to change { JobStatus.count }.by 1
          JobStatus.update_status_started( job_id: job.job_id )
          expect( JobStatus.status?( job_id: job.job_id, status: old_status ) ).to eq false
          expect( JobStatus.status?( job_id: job.job_id, status: new_status ) ).to eq true
        end
      end
    end

  end

  describe "add error" do
    let( :error1 ) { "First" }
    let( :error2 ) { "Second" }
    let( :error3 ) { "Third" }
    let( :sep )    { "--" }

    describe ".add_error" do
      context "adds errors to the record" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "adds" do
          job_status = nil
          expect { job_status = JobStatus.create( job_id: job.job_id,
                                                  job_class: job.class ) }.to change { JobStatus.count }.by 1
          expect( job_status.null_job_status? ).to eq false
          expect( job_status.error ).to eq nil
          expect do
            job_status.add_error( error1 ).save
            job_status.reload
          end.to_not change { JobStatus.count }
          expect(job_status.reload.error).to eq error1
          expect { job_status.add_error( error2 ).save }.to_not change { JobStatus.count }
          expect(job_status.reload.error).to eq "#{error1}\n#{error2}"
          expect { job_status.add_error( error3, sep: sep ).save }.to_not change { JobStatus.count }
          expect(job_status.reload.error).to eq "#{error1}\n#{error2}#{sep}#{error3}"
        end
      end
    end

    describe ".add_error!" do
      context "adds errors to the record" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "adds" do
          job_status = nil
          expect { job_status = JobStatus.create( job_id: job.job_id,
                                                  job_class: job.class ) }.to change { JobStatus.count }.by 1
          expect( job_status.null_job_status? ).to eq false
          expect( job_status.error ).to eq nil
          expect { job_status.add_error!( error1 ) }.to_not change { JobStatus.count }
          expect(job_status.reload.error).to eq error1
          expect { job_status.add_error!( error2 ) }.to_not change { JobStatus.count }
          expect(job_status.reload.error).to eq "#{error1}\n#{error2}"
          expect { job_status.add_error!( error3, sep: sep ) }.to_not change { JobStatus.count }
          expect(job_status.reload.error).to eq "#{error1}\n#{error2}#{sep}#{error3}"
        end
      end
    end

  end

  describe "add message" do
    let( :message1 ) { "First" }
    let( :message2 ) { "Second" }
    let( :message3 ) { "Third" }
    let( :sep )      { "--" }

    describe ".add_message" do
      context "adds messages to the record" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "adds" do
          job_status = nil
          expect { job_status = JobStatus.create( job_id: job.job_id,
                                                  job_class: job.class ) }.to change { JobStatus.count }.by 1
          expect( job_status.null_job_status? ).to eq false
          expect( job_status.message ).to eq nil
          expect do
            job_status.add_message( message1 ).save
            job_status.reload
          end.to_not change { JobStatus.count }
          expect(job_status.reload.message).to eq message1
          expect { job_status.add_message( message2 ).save }.to_not change { JobStatus.count }
          expect(job_status.reload.message).to eq "#{message1}\n#{message2}"
          expect { job_status.add_message( message3, sep: sep ).save }.to_not change { JobStatus.count }
          expect(job_status.reload.message).to eq "#{message1}\n#{message2}#{sep}#{message3}"
        end
      end
    end

    describe ".add_message!" do
      context "adds messages to the record" do
        let( :job ) { TestJob.send( :job_or_instantiate ) }
        it "adds" do
          job_status = nil
          expect { job_status = JobStatus.create( job_id: job.job_id,
                                                  job_class: job.class ) }.to change { JobStatus.count }.by 1
          expect( job_status.null_job_status? ).to eq false
          expect( job_status.message ).to eq nil
          expect { job_status.add_message!( message1 ) }.to_not change { JobStatus.count }
          expect(job_status.reload.message).to eq message1
          expect { job_status.add_message!( message2 ) }.to_not change { JobStatus.count }
          expect(job_status.reload.message).to eq "#{message1}\n#{message2}"
          expect { job_status.add_message!( message3, sep: sep ) }.to_not change { JobStatus.count }
          expect(job_status.reload.message).to eq "#{message1}\n#{message2}#{sep}#{message3}"
        end
      end
    end

  end

  describe "serialize and deserialize state" do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

  describe "null job state" do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

end
