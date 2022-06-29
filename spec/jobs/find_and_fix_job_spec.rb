# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FindAndFixJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.find_and_fix_job_debug_verbose ).to eq debug_verbose }
  end

  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'defines scheduler entry' do
    it 'has scheduler entry' do
      expect( described_class::SCHEDULER_ENTRY ).to include( "class: #{described_class.name}" )
    end
  end

  describe 'find and fix job' do
    let(:task) { false }
    let(:verbose) { false }
    let(:options) { args }
    let(:job)     { described_class.send( :job_or_instantiate, *args ) }

    RSpec.shared_examples 'it called initialize_from_args during perform job' do |run_on_server, dbg_verbose|
      before do
        described_class.find_and_fix_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose

        expect( described_class.find_and_fix_job_debug_verbose ).to eq dbg_verbose
        expect(job).to_not receive(:email_failure).with(any_args)
        expect(job).to receive( :initialize_from_args ).with( any_args ).and_call_original
        { quiet:                false,
          task:                 false,
          verbose:              false
        }.each_pair do |key,value|
          expect(job).to receive(:job_options_value).with( key: key.to_s,
                                                           default_value: value,
                                                           no_msg_handler: true ).at_least(:once).and_call_original
        end
        { by_request_only:         false,
          from_dashboard:          '',
          email_results_to:        [],
          hostnames:               [],
          job_delay:            0,
          subscription_service_id: nil,
          user_email:              []
        }.each_pair do |key,value|
          expect(job).to receive(:job_options_value).with( key: key.to_s,
                                                           default_value: value ).at_least(:once).and_call_original
        end
        expect(sched_helper).to receive(:log).with( class_name: described_class.name )
        if run_on_server
          { filter_date_begin:    nil,
            filter_date_end:      nil }.each_pair do |key,value|

            expect(job).to receive(:job_options_value).with( key: key.to_s,
                                                             default_value: value ).and_call_original
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
      let(:args)   { { 'email_results_to' => 'fritx@umich.edu',
                       'hostnames' => hostnames,
                       'subscription_service_id' => 'find_and_fix_job',
                       'verbose' => verbose } }
      run_on_server = true

      it_behaves_like 'it called initialize_from_args during perform job', run_on_server, true
      it_behaves_like 'it called initialize_from_args during perform job', run_on_server, false

    end

    describe 'without valid hostnames', skip: false do
      let(:hostnames) { build(:hostnames_not_allowed) }
      let(:args)   { { 'email_results_to' => 'fritx@umich.edu',
                       'hostnames' => hostnames,
                       'subscription_service_id' => 'find_and_fix_job',
                       'verbose' => verbose } }
      run_on_server = false

      it_behaves_like 'it called initialize_from_args during perform job', run_on_server, true
      it_behaves_like 'it called initialize_from_args during perform job', run_on_server, false

    end

    describe 'runs the job with SCHEDULER_ENTRY args' do
      let(:scheduler_entry) { described_class::SCHEDULER_ENTRY }
      let(:yaml)            { YAML.load scheduler_entry }
      let(:args)            { yaml[yaml.keys.first]['args'] }
      let(:hostnames)       { args['hostnames'] }
      let(:options)         { args.with_indifferent_access }

      run_on_server = false
      it_behaves_like 'it called initialize_from_args during perform job', run_on_server, false
      it_behaves_like 'it called initialize_from_args during perform job', run_on_server, true
    end

  end

end
