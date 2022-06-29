require 'rails_helper'

class MockDeepblueJob < ::Deepblue::DeepblueJob

  def perform(*args)
    initialize_options_from(*args)
  end

end

RSpec.describe ::Deepblue::DeepblueJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.deepblue_job_debug_verbose ).to eq debug_verbose }
  end

  describe '.email_all_targets' do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

  describe '.find_all_email_targets' do
    let(:job) { described_class.new }
    let(:email_target1) { 'emailTarget1' }
    let(:email_target2) { 'emailTarget2' }
    let(:email_target_redundant) { email_target1 }

    let(:email_targets) { [email_target1] }
    let(:additional_email_targets) { [email_target2,email_target_redundant] }
    before do
      job.email_targets = email_targets
    end
    it "it combines parms" do
      expect(job.email_targets).to eq email_targets
      job.find_all_email_targets( additional_email_targets: additional_email_targets )
      expect(job.email_targets).to eq [email_target1,email_target2]
    end
  end

  describe '.hostname_allowed' do
    let(:args) { {} }
    let(:job) { MockDeepblueJob.send( :job_or_instantiate, *args ) }

    it "calls job task helper" do
      expect( job.initialize_no_args_hash( debug_verbose: false ) ).to eq( {} )
      expect(job.hostname_allowed).to eq true
    end
  end

  describe '.initialize_no_args_hash' do

    let(:args) { {} }
    let(:job) { MockDeepblueJob.send( :job_or_instantiate, *args ) }
    it 'does it' do
      expect( job ).to receive(:job_status_init).and_call_original
      expect( job ).to receive(:email_targets_init).and_call_original
      expect( job ).to receive(:timestamp_begin).and_call_original
      expect( job.initialize_no_args_hash( debug_verbose: false ) ).to eq( {} )
      expect( job.debug_verbose ).to eq false
      expect( job.options ).to eq( {} )
      expect( job.task ).to eq false
      expect( job.verbose ).to eq false
    end

  end

  describe '.initialize_options_from' do
    let(:debug_verbose) { false }
    let(:args)  { {x: 'y'} }
    let(:args2) { {x: 'y', a: 'b'} }
    let(:init)  { [[:x,'y']] }
    let(:init2) { [[:x,'y'],[:a,'b']] }

    it 'it calls initialize options from with the right args 1' do
      expect(::Deepblue::JobTaskHelper).to receive(:initialize_options_from)
                                             .with(*init, debug_verbose: debug_verbose).and_call_original
      expect(::Deepblue::JobTaskHelper).to receive(:normalize_args)
                                             .with(*init, debug_verbose: debug_verbose).and_call_original
      MockDeepblueJob.perform_now(*args)
    end

    it 'it calls initialize options from with the right args 1' do
      expect(::Deepblue::JobTaskHelper).to receive(:initialize_options_from)
                                             .with(*init2, debug_verbose: debug_verbose).and_call_original
      expect(::Deepblue::JobTaskHelper).to receive(:normalize_args)
                                             .with(*init2, debug_verbose: debug_verbose).and_call_original
      MockDeepblueJob.perform_now(*args2)
    end

    context 'it sets options to the correct values 1' do
      let(:job) { MockDeepblueJob.send( :job_or_instantiate, *args ) }
      it 'does it' do
        expect(::Deepblue::JobTaskHelper).to receive(:initialize_options_from).with(*init,
                                                                                    debug_verbose: debug_verbose).and_call_original
        expect(::Deepblue::JobTaskHelper).to receive(:normalize_args).with(*init,
                                                                           debug_verbose: debug_verbose).and_call_original
        job.perform_now
        expect( job.options ).to eq( args.with_indifferent_access )
      end
    end

    context 'it sets options to the correct values 2' do
      let(:job) { MockDeepblueJob.send( :job_or_instantiate, *args2 ) }
      it 'does it' do
        expect(::Deepblue::JobTaskHelper).to receive(:initialize_options_from).with(*init2,
                                                                                    debug_verbose: debug_verbose).and_call_original
        expect(::Deepblue::JobTaskHelper).to receive(:normalize_args).with(*init2,
                                                                           debug_verbose: debug_verbose).and_call_original
        job.perform_now
        expect( job.options ).to eq( args2.with_indifferent_access )
      end
    end

  end

end
