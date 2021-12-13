# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FindAndFixJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.find_and_fix_job_debug_verbose ).to eq debug_verbose }
  end

  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'find and fix job' do
    let(:task) { false }
    let(:verbose) { false }
    let(:args)   { { 'email_results_to' => 'fritx@umich.edu',
                     'hostnames' => hostnames,
                     'subscription_service_id' => 'find_and_fix_job',
                     'verbose' => verbose } }
    let(:options) { args }
    let(:job)     { described_class.send( :job_or_instantiate, *args ) }

    RSpec.shared_examples 'it called initialize_from_args during perform job' do |run_the_job, dbg_verbose|
      before do
        described_class.find_and_fix_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose

        expect( described_class.find_and_fix_job_debug_verbose ).to eq dbg_verbose
        expect(job).to receive( :initialize_from_args ).with( any_args ).and_call_original
        { task:                 false,
          verbose:              false,
          by_request_only:      false,
          from_dashboard:       '',
          is_quiet:             false,
          job_delay:            0,
          email_results_to:     [],
          subscription_service_id: nil,
          hostnames:            [] }.each_pair do |key,value|

          expect(job).to receive(:job_options_value).with( options,
                                                           key: key.to_s,
                                                           default_value: value,
                                                           verbose: false,
                                                           task: false ).and_call_original
        end
        expect(sched_helper).to receive(:log).with( class_name: described_class.name )
        if run_the_job
          { filter_date_begin:    nil,
            filter_date_end:      nil }.each_pair do |key,value|

            expect(job).to receive(:job_options_value).with( options,
                                                             key: key.to_s,
                                                             default_value: value,
                                                             verbose: false,
                                                             task: false ).and_call_original
          end
          expect(job).to receive(:run_job_delay).with(no_args) #.and_call_original
          expect(job).to receive(:email_results).with(any_args)
        else
          expect(job).to_not receive(:run_job_delay).with(no_args) #.and_call_original
          expect(job).to_not receive(:email_results).with(any_args)
        end

      end

      after do
        described_class.find_and_fix_job_debug_verbose = debug_verbose
      end

      it 'runs the job with the options specified' do
        ActiveJob::Base.queue_adapter = :test
        job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      end
    end

    describe 'with valid hostname' do
      let(:hostnames) { build(:hostnames_allowed) }
      run_the_job = true

      it_behaves_like 'it called initialize_from_args during perform job', run_the_job, true
      it_behaves_like 'it called initialize_from_args during perform job', run_the_job, false

    end

    describe 'without valid hostnames', skip: false do
      let(:hostnames) { build(:hostnames_not_allowed) }
      run_the_job = false

      it_behaves_like 'it called initialize_from_args during perform job', run_the_job, true
      it_behaves_like 'it called initialize_from_args during perform job', run_the_job, false

    end

  end

end
