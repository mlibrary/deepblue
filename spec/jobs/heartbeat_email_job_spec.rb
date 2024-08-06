require 'rails_helper'

RSpec.describe HeartbeatEmailJob do

  let(:debug_verbose)   {false}

  # let(:subject_job)  { class_double(HeartbeatEmailJob ).as_stubbed_const(:transfer_nested_constants => true) }
  # let(:sched_helper) { class_double(Deepblue::SchedulerHelper).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'module debug verbose variables' do
    it { expect( described_class.heartbeat_email_job_debug_verbose ).to eq debug_verbose }
  end

  describe 'defines scheduler entry' do
    it 'has scheduler entry' do
      expect( described_class::SCHEDULER_ENTRY ).to include( "class: #{described_class.name}" )
    end
  end

  RSpec.shared_examples 'it performs the job' do |run_on_server, debug_verbose_count|
    let(:event)        { "heartbeat email job" }
    let(:dbg_verbose)  { debug_verbose_count > 0 }
    let(:job)          { described_class.send( :job_or_instantiate, **args ) }
    let(:time_before)  { DateTime.now }

    before do
      expect(job).to receive(:perform_now).with(no_args).and_call_original
      expect(job).to receive(:job_status_init).with(id: nil, restartable: nil).and_call_original
      expect(job).to receive(:timestamp_begin).with(no_args).at_least(:once).and_call_original
      expect(job).to receive(:initialize_options_from).with(args: [args], debug_verbose: dbg_verbose).and_call_original
      expect(job).to receive(:hostname_allowed?).with(no_args).at_least(:once).and_call_original
      expect(job).to receive(:log).with({event: event, hostname_allowed: allowed})
      if run_on_server
        expect(job).to receive(:find_all_email_targets).with(additional_email_targets: email_targets).and_call_original
        expect(job).to receive(:email_all_targets).with(task_name: "scheduler heartbeat", event: event)
      end
      if 0 < debug_verbose_count
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
      else
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
      end
    end

    it 'it performs the job' do
      save_debug_verbose = described_class.heartbeat_email_job_debug_verbose
      described_class.heartbeat_email_job_debug_verbose = dbg_verbose
      expect(job.hostname).to eq Rails.configuration.hostname
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      time_after = DateTime.now
      expect(job.options).to eq options
      expect(job.verbose).to eq false
      expect(job.email_targets).to eq email_targets
      expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
      expect(job.job_status).to_not eq nil
      expect(job.job_status.status? JobStatus::FINISHED).to eq true
      described_class.heartbeat_email_job_debug_verbose = save_debug_verbose
    end

  end

  describe 'run the job' do

    context 'with valid arguments and allowed to run on server' do
      let(:allowed) { true }
      let(:email_targets) { ["fritx@umich.edu"] }
      let(:hostnames) { build(:hostnames_allowed) }
      let(:options)      { { "hostnames" => hostnames } }
      let(:args)         { { hostnames: hostnames } }

      run_on_server = true
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', run_on_server, debug_verbose_count
    end

    context 'with valid arguments and allowed to run on server debug verbose' do
      let(:allowed) { true }
      let(:email_targets) { ["fritx@umich.edu"] }
      let(:hostnames) { build(:hostnames_allowed) }
      let(:options)      { { "hostnames" => hostnames } }
      let(:args)         { { hostnames: hostnames } }

      run_on_server = true
      debug_verbose_count = 1
      it_behaves_like 'it performs the job', run_on_server, debug_verbose_count
    end

    context 'with valid arguments and not allowed to run on server' do
      let(:allowed) { false }
      let(:email_targets) { [] }
      let(:hostnames) { build(:hostnames_not_allowed) }
      let(:options)      { { "hostnames" => hostnames } }
      let(:args)         { { hostnames: hostnames } }

      run_on_server = false
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', run_on_server, debug_verbose_count
    end

    describe 'runs the job with SCHEDULER_ENTRY args' do
      let(:allowed) { false }
      let(:scheduler_entry) { described_class::SCHEDULER_ENTRY }
      let(:yaml)      { YAML.load scheduler_entry }
      let(:args)      { yaml[yaml.keys.first]['args'] }
      let(:options)   { args }
      let(:email_targets) { [] }
      let(:hostnames) { args['hostnames'] }

      run_on_server = false
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', run_on_server, debug_verbose_count
    end

  end

end
