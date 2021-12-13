# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RakeTaskJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.rake_task_job_debug_verbose ).to eq debug_verbose }
  end

  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'rake task job', skip: false do
    let(:rake_task) { 'run_this' }
    let(:task)      { false }
    let(:verbose)   { false }
    let(:args)      { { 'rake_task' => rake_task,
                        'hostnames' => hostnames,
                        'verbose' => verbose } }
    let(:options)   { args }
    let(:job)       { described_class.send( :job_or_instantiate, *args ) }

    RSpec.shared_examples 'it called initialize_from_args during perform job' do |run_the_job|
      before do
        expect( described_class.rake_task_job_debug_verbose ).to eq false
        expect(job).to receive(:initialize_from_args).with( any_args ).and_call_original
        { task:                 false,
          verbose:              false,
          by_request_only:      false,
          from_dashboard:       '',
          is_quiet:             false,
          job_delay:            0,
          email_results_to:     [],
          subscription_service_id: nil,
          hostnames:            [],
          rake_task:            '' }.each_pair do |key,value|

          expect(job).to receive(:job_options_value).with( options,
                                                           key: key.to_s,
                                                           default_value: value,
                                                           task: false,
                                                           verbose: false ).at_least(:once).and_call_original
        end
        if run_the_job
          expect(sched_helper).to receive(:log).with( class_name: described_class.name, event_note: rake_task )
          expect(job).to receive(:allowed_job_task?).with(no_args).and_return true
          expect(job).to receive(:run_job_delay).with(no_args) #.and_call_original
          expect(job).to receive(:exec_rake_task).with("bundle exec rake #{rake_task}").and_return 'Success!'
          expect(job).to receive(:email_exec_results).with(any_args)
        else
          expect(job).to_not receive(:allowed_job_task?).with(no_args)
          expect(job).to_not receive(:run_job_delay).with(no_args) #.and_call_original
          expect(job).to_not receive(:exec_rake_task).with(any_args)
          expect(job).to_not receive(:email_exec_results).with(any_args)
        end

      end

      it 'runs the job with the options specified' do
        ActiveJob::Base.queue_adapter = :test
        job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      end

    end

    describe 'with valid hostname' do
      let(:hostnames) { build(:hostnames_allowed) }
      run_the_job = true

      it_behaves_like 'it called initialize_from_args during perform job', run_the_job

    end

    describe 'without valid hostnames', skip: false do
      let(:hostnames) { build(:hostnames_not_allowed) }
      run_the_job = false

      it_behaves_like 'it called initialize_from_args during perform job', run_the_job

    end

    describe '.exec_rake_task' do
      let(:hostnames) { [] } # needed for creation of job
      it 'execs call to external program' do
        expect( job.exec_rake_task( "echo this_is_test") ).to eq "this_is_test\n"
      end
    end

  end

  describe 'example.allowed_job_task?', skip: true do
    RSpec.shared_examples 'shared #example' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.apply_order_actor_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.apply_order_actor_debug_verbose = debug_verbose
      end
      context do
      end
    end
    it_behaves_like 'shared #example', false
    it_behaves_like 'shared #example', true
  end

 describe '.allowed_job_task?', skip: false do
    let(:hostnames) { [] } # needed for creation of job
    let(:task)      { false }
    let(:verbose)   { false }

    context 'when not allowed', skip: false do
      let(:rake_task) { 'not_allowed_task' }
      let(:args)      { { 'rake_task' => rake_task,
                          'hostnames' => hostnames,
                          'verbose' => verbose } }
      let(:job)       { described_class.send( :job_or_instantiate, *args ) }

      before do
        expect(job).to_not receive(:exec_rake_task)
      end

      it 'returns false' do
        ActiveJob::Base.queue_adapter = :test
        job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
        expect(job.allowed_job_task?).to eq false
      end

    end

    context 'when allowed', skip: false do
      let(:rake_task) { '-T' } # allowed task
      let(:args)      { { 'rake_task' => rake_task,
                          'hostnames' => hostnames,
                          'verbose' => verbose } }
      let(:job)       { described_class.send( :job_or_instantiate, *args ) }

      before do
        expect(job).to receive(:exec_rake_task).with( "bundle exec rake #{rake_task}" ).and_return ''
      end

      it 'returns true' do
        ActiveJob::Base.queue_adapter = :test
        job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
        expect(job.allowed_job_task?).to eq true
      end

    end

    context 'when allowed and via matching', skip: false do
      let(:rake_task) { 'blacklight:delete_old_searches[30]' } # allowed task via matching
      let(:args)      { { 'rake_task' => rake_task,
                          'hostnames' => hostnames,
                          'verbose' => verbose } }
      let(:job)       { described_class.send( :job_or_instantiate, *args ) }

      before do
        expect(job).to receive(:exec_rake_task).with( "bundle exec rake #{rake_task}" ).and_return ''
      end

      it 'returns true' do
        ActiveJob::Base.queue_adapter = :test
        job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
        expect(job.allowed_job_task?).to eq true
      end

    end

  end

end
