# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RakeTaskJob, skip: false do

  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.rake_task_job_debug_verbose ).to eq( false )
    end
  end

  describe 'rake task job' do
    let(:job)       { described_class.send( :job_or_instantiate, *args ) }
    let(:rake_task) { 'run_this' }
    let(:verbose)   { false }
    let(:args)   { { 'rake_task' => rake_task,
                     'hostnames' => hostnames,
                     'verbose' => verbose } }
    let(:options) { args }

    RSpec.shared_examples 'it called initialize_from_args during perform job' do |run_the_job|
      before do
        expect( described_class.rake_task_job_debug_verbose ).to eq false
        expect( job ).to receive( :initialize_from_args ).with( any_args ).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'verbose',
                                                             default_value: false ).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'job_delay',
                                                             default_value: 0,
                                                             verbose: verbose ).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'email_results_to',
                                                             default_value: [],
                                                             verbose: verbose ).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'subscription_service_id',
                                                             default_value: nil,
                                                             verbose: verbose ).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'hostnames',
                                                             default_value: [],
                                                             verbose: verbose ).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'rake_task',
                                                             default_value: '',
                                                             verbose: verbose ).and_call_original
        expect(sched_helper).to receive(:log).with( class_name: described_class.name, event_note: rake_task )
        if run_the_job
          expect( job ).to receive(:allowed_job_task?).with(no_args).and_return true
          expect( job ).to receive(:run_job_delay).with(no_args) #.and_call_original
          expect( job ).to receive(:exec_rake_task).with("bundle exec rake #{rake_task}").and_return 'Success!'
          expect( job ).to receive(:email_exec_results).with(any_args)
        else
          expect( job ).to_not receive(:allowed_job_task?).with(no_args)
          expect( job ).to_not receive(:run_job_delay).with(no_args) #.and_call_original
          expect( job ).to_not receive(:exec_rake_task).with(any_args)
          expect( job ).to_not receive(:email_exec_results).with(any_args)
        end

      end

      it 'runs the job with the options specified' do
        ActiveJob::Base.queue_adapter = :test
        job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      end

    end

    describe 'with valid hostname' do
      let(:hostnames) { [ ::DeepBlueDocs::Application.config.hostname,
                          'deepblue.lib.umich.edu',
                          'staging.deepblue.lib.umich.edu',
                          'testing.deepblue.lib.umich.edu' ] }
      run_the_job = true

      it_behaves_like 'it called initialize_from_args during perform job', run_the_job

    end

    describe 'without valid hostnames', skip: false do
      let(:hostnames) { [ 'deepblue.lib.umich.edu',
                          'staging.deepblue.lib.umich.edu',
                          'testing.deepblue.lib.umich.edu' ] }
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

end
