require 'rails_helper'

RSpec.describe AboutToExpireEmbargoesJob do

  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect(described_class.about_to_expire_embargoes_job_debug_verbose).to eq debug_verbose
    end
  end

  describe 'module variables' do
    it "they have the right values" do
      expect(described_class.default_args).to eq( { email_owner: true,
                                                    expiration_lead_days: 7,
                                                    skip_file_sets: true,
                                                    test_mode: false,
                                                    task: false,
                                                    verbose: false } )
    end
  end

  describe 'shared' do

    RSpec.shared_examples 'AboutToExpireEmbargoesJob' do |run_the_job, debug_verbose_count|
      let(:job)           { described_class.send( :job_or_instantiate, *args ) }
      let(:dbg_verbose)   { debug_verbose_count > 0 }
      let(:service)       { double('service') }
      let(:options)       { args }
      let(:job_msg_queue) { [] }
      let(:event_name)    { 'about to expire embargoes' }
      let(:time_before)   { DateTime.now }
      before do
        task = args["task"]
        task = described_class.default_args[:task] if task.blank?
        verbose = args["verbose"]
        verbose = described_class.default_args[:verbose] if verbose.blank?
        email_owner = args["email_owner"]
        email_owner = described_class.default_args[:email_owner] if email_owner.blank?
        expiration_lead_days = args["expiration_lead_days"]
        expiration_lead_days = described_class.default_args[:expiration_lead_days] if expiration_lead_days.blank?
        skip_file_sets = args["skip_file_sets"]
        skip_file_sets = described_class.default_args[:skip_file_sets] if skip_file_sets.blank?
        test_mode = args["test_mode"]
        test_mode = described_class.default_args[:test_mode] if test_mode.blank?
        expect( described_class.about_to_expire_embargoes_job_debug_verbose ).to eq false
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
        expect(job).to receive(:options_value).with( key: 'email_owner',
                                                     default_value: described_class.default_args[:email_owner] ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'email_owner',
                                                         default_value: described_class.default_args[:email_owner],
                                                         verbose: verbose,
                                                         task: task ).and_call_original
        expect(job).to receive(:options_value).with( key: 'expiration_lead_days',
                                                     default_value: described_class.default_args[:expiration_lead_days] ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                           key: 'expiration_lead_days',
                                           default_value: described_class.default_args[:expiration_lead_days],
                                           verbose: verbose,
                                           task: task ).and_call_original
        expect(job).to receive(:options_value).with( key: 'skip_file_sets',
                                                     default_value: described_class.default_args[:skip_file_sets] ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'skip_file_sets',
                                                         default_value: described_class.default_args[:skip_file_sets],
                                                         verbose: verbose,
                                                         task: task ).and_call_original
        expect(job).to receive(:options_value).with( key: 'test_mode',
                                                     default_value: described_class.default_args[:test_mode] ).and_call_original
        expect(job).to receive(:job_options_value).with( options,
                                                         key: 'test_mode',
                                                         default_value: described_class.default_args[:test_mode],
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
          expect(::Deepblue::AboutToExpireEmbargoesService).to receive(:new).with(email_owner: email_owner,
                                                    expiration_lead_days: expiration_lead_days,
                                                    job_msg_queue: job_msg_queue,
                                                    skip_file_sets: skip_file_sets,
                                                    test_mode: test_mode,
                                                    verbose: verbose).and_return service
          expect(job).to receive(:email_results).with(any_args)
        else
          expect(::Deepblue::AboutToExpireEmbargoesService).to_not receive(:new)
          expect(job).to_not receive(:email_results).with(any_args)
        end

      end

      it 'it runs the job' do
        save_debug_verbose = described_class.about_to_expire_embargoes_job_debug_verbose
        described_class.about_to_expire_embargoes_job_debug_verbose = dbg_verbose
        ActiveJob::Base.queue_adapter = :test
        job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
        time_after = DateTime.now
        expect(job.options).to eq options
        expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
        described_class.about_to_expire_embargoes_job_debug_verbose = save_debug_verbose
      end

    end

    describe 'runs the job' do
      let(:args)        { { "email_owner" => true, "test_mode" => false, "verbose" => true } }

      run_the_job = true

      debug_verbose_count = 0
      it_behaves_like 'AboutToExpireEmbargoesJob', run_the_job, debug_verbose_count

    end

    describe 'runs the job empty args' do
      let(:args)        { {} }

      run_the_job = true

      debug_verbose_count = 0
      it_behaves_like 'AboutToExpireEmbargoesJob', run_the_job, debug_verbose_count

    end

    describe 'runs the job all args' do
      let(:args)        { { "email_owner" => true,
                            "expiration_lead_days" => 11,
                            "skip_file_sets" => true,
                            "test_mode" => true,
                            "verbose" => true } }

      run_the_job = true

      debug_verbose_count = 0
      it_behaves_like 'AboutToExpireEmbargoesJob', run_the_job, debug_verbose_count

    end

    describe 'runs the job debug verbose' do
      let(:args)        { { "email_owner" => true, "test_mode" => false, "verbose" => true } }

      run_the_job = true

      debug_verbose_count = 1
      it_behaves_like 'AboutToExpireEmbargoesJob', run_the_job, debug_verbose_count

    end

  end

end
