require 'rails_helper'

RSpec.describe CleanDerivativesDirJob do

  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect(described_class.clean_derivatives_dir_job_debug_verbose).to eq( false )
      expect(described_class.default_args).to eq( { days_old: 7,
                                                    to_console: false,
                                                    task: false,
                                                    verbose: false } )
    end
  end

  describe 'shared' do

    RSpec.shared_examples 'CleanDerivativesDirJob' do |run_the_job, debug_verbose_count|
      let(:job)           { described_class.send( :job_or_instantiate, *args ) }
      let(:dbg_verbose)   { debug_verbose_count > 0 }
      let(:service)       { double('service') }
      let(:options)       { args }
      let(:job_msg_queue) { [] }
      let(:event_name)    { 'clean derivatives dir' }
      let(:time_before)   { DateTime.now - 1.second }
      let(:to_console)    { false }
      before do
        task = args["task"]
        task = described_class.default_args[:task] if task.blank?
        verbose = args["verbose"]
        verbose = described_class.default_args[:verbose] if verbose.blank?
        days_old = args["days_old"]
        days_old = described_class.default_args[:days_old] if days_old.blank?
        expect( described_class.clean_derivatives_dir_job_debug_verbose ).to eq false
        expect(job).to receive(:initialize_from_args).with( any_args ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'task',
                                                         default_value: described_class.default_args[:task],
                                                         task: false ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'verbose',
                                                         default_value: described_class.default_args[:verbose],
                                                         task: task ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'job_delay',
                                                         default_value: 0,
                                                         verbose: verbose,
                                                         task: task ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'email_results_to',
                                                         default_value: [],
                                                         verbose: verbose,
                                                         task: task ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'subscription_service_id',
                                                         default_value: nil,
                                                         verbose: verbose,
                                                         task: task ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'hostnames',
                                                         default_value: [],
                                                         verbose: verbose,
                                                         task: task ).and_call_original
        expect(job).to receive(:options_value).with( key: 'days_old',
                                                     default_value: described_class.default_args[:days_old] ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'days_old',
                                                         default_value: described_class.default_args[:days_old],
                                                         verbose: verbose,
                                                         task: task ).and_call_original
        expect(sched_helper).to receive(:log).with(class_name: described_class.name, event: event_name )
        if 0 < debug_verbose_count
          expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
        else
          expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
        end
        expect(service).to receive(:run)
        if run_the_job
          expect(::Deepblue::CleanDerivativesDirService).to receive(:new).with(days_old: days_old,
                                                                               job_msg_queue: job_msg_queue,
                                                                               to_console: to_console,
                                                                               verbose: verbose).and_return service
        else
          expect(::Deepblue::CleanDerivativesDirService).to_not receive(:new)
        end

      end

      it 'it runs the job' do
        save_debug_verbose = described_class.clean_derivatives_dir_job_debug_verbose
        described_class.clean_derivatives_dir_job_debug_verbose = dbg_verbose
        ActiveJob::Base.queue_adapter = :test
        job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
        time_after = DateTime.now + 1.second
        expect(job.options).to eq options
        expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
        described_class.clean_derivatives_dir_job_debug_verbose = save_debug_verbose
      end

    end

    describe 'runs the job' do
      let(:args)        { { "verbose" => true } }

      run_the_job = true

      debug_verbose_count = 0
      it_behaves_like 'CleanDerivativesDirJob', run_the_job, debug_verbose_count

    end

    describe 'runs the job empty args' do
      let(:args)        { {} }

      run_the_job = true

      debug_verbose_count = 0
      it_behaves_like 'CleanDerivativesDirJob', run_the_job, debug_verbose_count

    end

    describe 'runs the job all args' do
      let(:args)        { { "days_old" => 11,
                            "to_console" => false,
                            "verbose" => true } }

      run_the_job = true

      debug_verbose_count = 0
      it_behaves_like 'CleanDerivativesDirJob', run_the_job, debug_verbose_count

    end

    describe 'runs the job debug verbose' do
      let(:args)        { { "verbose" => true } }

      run_the_job = true

      debug_verbose_count = 1
      it_behaves_like 'CleanDerivativesDirJob', run_the_job, debug_verbose_count

    end

  end

end
