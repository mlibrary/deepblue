require 'rails_helper'

RSpec.describe HeartbeatEmailJob do

  let(:debug_verbose)   {false}

  # let(:subject_job)  { class_double(HeartbeatEmailJob ).as_stubbed_const(:transfer_nested_constants => true) }
  # let(:sched_helper) { class_double(Deepblue::SchedulerHelper).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.heartbeat_email_job_debug_verbose ).to eq debug_verbose
    end
  end

  describe 'defines scheduler entry' do
    it 'has scheduler entry' do
      expect( described_class::SCHEDULER_ENTRY ).to include( "class: #{described_class.name}" )
    end
  end

  context 'with valid arguments and allowed to run on server' do
    let(:allowed) { true }
    let(:email_targets) { ["fritx@umich.edu"] }
    let(:event)   { "heartbeat email" }
    let(:hostnames) { build(:hostnames_allowed) }
    let(:args)    { { hostnames: hostnames } }
    let(:job)     { described_class.send( :job_or_instantiate, *args ) }
    let(:options) { { "hostnames" => hostnames } }
    let(:time_before) { DateTime.now }

    before do
      expect(job).to receive(:perform_now).with(no_args).and_call_original
      expect(job).to receive(:job_status_init).with(no_args).and_call_original
      expect(job).to receive(:timestamp_begin).with(no_args).at_least(:once).and_call_original
      expect(job).to receive(:initialize_options_from).with(*args, {:debug_verbose=>debug_verbose}).and_call_original
      expect(job).to receive(:hostname_allowed).with({:debug_verbose=>debug_verbose}).and_call_original
      expect(job).to receive(:log).with({event: event, hostname_allowed: allowed})
      expect(job).to receive(:find_all_email_targets).with(additional_email_targets: email_targets).and_call_original
      expect(job).to receive(:email_all_targets).with(task_name: "scheduler heartbeat", event: event)
    end

    it 'it performs the job' do
      expect(job.hostname).to eq ::DeepBlueDocs::Application.config.hostname
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      time_after = DateTime.now
      expect(job.options).to eq options
      expect(job.verbose).to eq false
      expect(job.email_targets).to eq email_targets
      expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
      expect(job.job_status).to_not eq nil
      expect(job.job_status.status? JobStatus::FINISHED).to eq true
    end

  end

  context 'with valid arguments and not allowed to run on server' do
    let(:allowed) { false }
    let(:email_targets) { [] }
    let(:event)   { "heartbeat email" }
    let(:hostnames) { build(:hostnames_not_allowed) }
    let(:args)    { { hostnames: hostnames } }
    let(:job)     { described_class.send( :job_or_instantiate, *args ) }
    let(:options) { { "hostnames" => hostnames } }
    let(:time_before) { DateTime.now }

    before do
      expect(job).to receive(:perform_now).with(no_args).and_call_original
      expect(job).to receive(:job_status_init).with(no_args).and_call_original
      expect(job).to receive(:timestamp_begin).with(no_args).at_least(:once).and_call_original
      expect(job).to receive(:initialize_options_from).with(*args, {:debug_verbose=>debug_verbose}).and_call_original
      expect(job).to receive(:hostname_allowed).with({:debug_verbose=>debug_verbose}).and_call_original
      expect(job).to receive(:log).with({event: event, hostname_allowed: allowed})
      expect(job).to_not receive(:find_all_email_targets)
      expect(job).to_not receive(:email_all_targets)
    end

    it 'it performs the job' do
      expect(job.hostname).to eq ::DeepBlueDocs::Application.config.hostname
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      time_after = DateTime.now
      expect(job.options).to eq options
      expect(job.verbose).to eq false
      expect(job.email_targets).to eq email_targets
      expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
      expect(job.job_status).to_not eq nil
      expect(job.job_status.status? JobStatus::FINISHED).to eq true
    end

  end

end
