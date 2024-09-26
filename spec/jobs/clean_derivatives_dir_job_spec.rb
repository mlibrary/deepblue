require 'rails_helper'

RSpec.describe CleanDerivativesDirJob do

  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'module debug verbose variables' do
    it { expect(described_class.clean_derivatives_dir_job_debug_verbose).to eq false }
    it { expect(described_class.default_args).to eq( { by_request_only: false,
                                                       from_dashboard: '',
                                                       is_quiet: false,
                                                       days_old: 7,
                                                       to_console: false,
                                                       task: false,
                                                       verbose: false } ) }
  end

  describe 'defines scheduler entry' do
    it 'has scheduler entry' do
      expect( described_class::SCHEDULER_ENTRY ).to include( "class: #{described_class.name}" )
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
        # task = args["task"]
        # task = described_class.default_args[:task] if task.blank?
        verbose = args["verbose"]
        verbose = described_class.default_args[:verbose] if verbose.blank?
        days_old = args["days_old"]
        days_old = described_class.default_args[:days_old] if days_old.blank?
        expect( described_class.clean_derivatives_dir_job_debug_verbose ).to eq false
        expect(job).to receive(:initialize_from_args).with( any_args ).and_call_original
        { quiet:                false,
          task:                 false,
          verbose:              false
        }.each_pair do |key,value|
          expect(job).to receive(:job_options_value).with( key: key.to_s,
                                                           default_value: value,
                                                           no_msg_handler: true ).at_least(:once).and_call_original
        end
        { by_request_only:      described_class.default_args[:by_request_only],
          from_dashboard:       described_class.default_args[:from_dashboard],
          job_delay:            0,
          email_results_to:     [],
          subscription_service_id: nil,
          hostnames:            [],
          days_old:             described_class.default_args[:days_old],
          user_email:           []
        }.each_pair do |key,value|
          expect(job).to receive(:job_options_value).with( key: key.to_s,
                                                           default_value: value ).at_least(:once).and_call_original
        end
        expect(sched_helper).to receive(:log).with(class_name: described_class.name, event: event_name )
        if 0 < debug_verbose_count
          expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
        else
          expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
        end
        expect(service).to receive(:run)
        if run_the_job
          expect(::Deepblue::CleanDerivativesDirService).to receive(:new) do |args|
            expect(args[:days_old]).to eq days_old
            # expect(args[:job_msg_queue]).to eq job_msg_queue
            expect(args[:msg_handler].to_console).to eq to_console
            expect(args[:msg_handler].verbose).to eq verbose
          end.and_return service
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

    describe 'runs the job with SCHEDULER_ENTRY args' do
      let(:scheduler_entry) { described_class::SCHEDULER_ENTRY }
      let(:yaml) { YAML.load scheduler_entry }
      let(:args) { yaml[yaml.keys.first]['args'] }

      run_the_job = true

      debug_verbose_count = 0
      it_behaves_like 'CleanDerivativesDirJob', run_the_job, debug_verbose_count

    end

  end

end
