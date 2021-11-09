# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonthlyEventsReportJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.monthly_events_report_job_debug_verbose ).to eq debug_verbose
    end
  end

  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'monthly events report job' do
    let(:this_month) { false }
    let(:quiet)      { true }
    let(:verbose)    { false }
    let(:task)       { false }
    let(:args)   { { 'hostnames' => hostnames,
                     'quiet' => quiet,
                     'this_month' => this_month,
                     'subscription_service_id' => 'monthly_events_report' } }
    let(:options) { args }
    let(:job)     { described_class.send( :job_or_instantiate, *args ) }

    RSpec.shared_examples 'it called initialize_from_args during perform job' do |run_the_job, dbg_verbose|
      before do
        described_class.monthly_events_report_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose

        expect( described_class.monthly_events_report_job_debug_verbose ).to eq dbg_verbose
        expect( job ).to receive( :initialize_options_from ).with( any_args ).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'task',
                                                             default_value: false,
                                                             task: task ).at_least(:once).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'verbose',
                                                             default_value: false,
                                                             task: task ).at_least(:once).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'quiet',
                                                             default_value: false,
                                                             verbose: verbose || dbg_verbose,
                                                             task: task ).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'hostnames',
                                                             default_value: [],
                                                             verbose: verbose || dbg_verbose,
                                                             task: task ).at_least(:once).and_call_original
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'user_email',
                                                             default_value: '',
                                                             task: task ).and_call_original
        expect(sched_helper).to receive(:log) do |args|
          expect( args[:class_name]).to eq described_class.name
          expect( args[:event] ).to eq "monthly events report job"
        end
        expect(sched_helper).to receive( :echo_to_rails_logger ).with(any_args).and_return false
        if run_the_job
          expect( job ).to receive( :job_options_value ).with( options,
                                                               key: 'this_month',
                                                               default_value: false,
                                                               task: task ).and_call_original
          expect( job ).to receive(:quiet).with(any_args)
          expect(::AnalyticsHelper).to receive(:monthly_events_report).with(no_args)
        else
          # expect( job ).to_not receive(:run_job_delay).with(no_args) #.and_call_original
          expect( job ).to receive(:quiet).with(any_args)
          expect(::AnalyticsHelper).to_not receive(:monthly_events_report).with(any_args)
        end
      end
      after do
        described_class.monthly_events_report_job_debug_verbose = debug_verbose
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
