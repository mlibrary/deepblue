require 'rails_helper'

RSpec.describe AboutToExpireEmbargoesJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect(described_class.about_to_expire_embargoes_job_debug_verbose).to eq debug_verbose }
  end

  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'module variables' do
    it { expect(described_class.default_args).to eq( { by_request_only: false,
                                                       from_dashboard: '',
                                                       email_owner: true,
                                                       expiration_lead_days: 7,
                                                       is_quiet: false,
                                                       skip_file_sets: true,
                                                       test_mode: false,
                                                       task: false,
                                                       verbose: false } ) }
  end

  describe 'defines scheduler entry' do
    it 'has scheduler entry' do
      expect( described_class::SCHEDULER_ENTRY ).to include( "class: #{described_class.name}" )
    end
  end

  describe 'shared' do

    RSpec.shared_examples 'AboutToExpireEmbargoesJob' do |run_the_job, debug_verbose_count|
      let(:job)           { described_class.send(:job_or_instantiate, **args) }
      let(:dbg_verbose)   { debug_verbose_count > 0 }
      let(:service)       { double('service') }
      let(:options)       { args }
      let(:event_name)    { 'about to expire embargoes' }
      let(:time_before)   { DateTime.now }
      before do
        # args overrides verbose
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
          # is_quiet:             described_class.default_args[:is_quiet],
          job_delay:            0,
          email_results_to:     [],
          subscription_service_id: nil,
          hostnames:            [],
          email_owner:          described_class.default_args[:email_owner],
          expiration_lead_days: described_class.default_args[:expiration_lead_days],
          skip_file_sets:       described_class.default_args[:skip_file_sets],
          test_mode:            described_class.default_args[:test_mode],
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
          expect(::Deepblue::AboutToExpireEmbargoesService).to receive(:new) do |args|
            expect(args[:email_owner]).to eq email_owner
            expect(args[:expiration_lead_days]).to eq expiration_lead_days
            expect(args[:skip_file_sets]).to eq skip_file_sets
            expect(args[:test_mode]).to eq test_mode
            # expect(args[:verbose]).to eq verbose
            expect(args[:msg_handler].is_a? ::Deepblue::MessageHandler).to eq true
            # expect(args[:msg_handler].msg_queue).to eq []
            expect(args[:msg_handler].to_console).to eq false
            expect(args[:msg_handler].verbose).to eq verbose
            expect(args[:msg_handler].debug_verbose).to eq dbg_verbose
          end.and_return service
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
        job.perform_now # arguments set in the describe_class.send :job_or_instantiate above
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

    describe 'runs the job with SCHEDULER_ENTRY args' do
      let(:scheduler_entry) { described_class::SCHEDULER_ENTRY }
      let(:yaml) { YAML.load scheduler_entry }
      let(:args) { yaml[yaml.keys.first]['args'] }

      run_the_job = true

      debug_verbose_count = 0
      it_behaves_like 'AboutToExpireEmbargoesJob', run_the_job, debug_verbose_count

    end

  end

end
