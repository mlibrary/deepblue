require 'rails_helper'

RSpec.describe WorkFindAndFixJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( ::Deepblue::JobTaskHelper.work_find_and_fix_job_debug_verbose ).to eq debug_verbose }
  end

  RSpec.shared_examples 'it performs the job' do |debug_verbose_count|
    let(:dbg_verbose) { debug_verbose_count > 0 }
    let(:id)          { 'workid' }
    let(:args)        { {} }
    let(:job)         { described_class.send( :job_or_instantiate, id, *args ) }

    before do
      expect(job).to receive(:perform_now).with(no_args).and_call_original
      if 0 < debug_verbose_count
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
      else
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
      end
    end

    it 'it performs the job' do
      save_debug_verbose = described_class.work_find_and_fix_job_debug_verbose
      described_class.work_find_and_fix_job_debug_verbose = dbg_verbose
      expect(described_class.work_find_and_fix_job_debug_verbose).to eq dbg_verbose
      allow(job).to receive(:hostname_allowed?).and_return true
      expect(::Deepblue::FindAndFixService).to receive(:work_find_and_fix) do |args|
        expect(args[:id]).to eq id
        expect(args[:msg_handler].is_a? ::Deepblue::MessageHandler).to eq true
        expect(args[:msg_handler].msg_queue).to eq []
        expect(args[:msg_handler].task).to eq false
        expect(args[:msg_handler].verbose).to eq false
        expect(args[:task]).to eq false
        # expect(args[:debug_verbose]).to eq debug_verbose
      end
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      described_class.work_find_and_fix_job_debug_verbose = save_debug_verbose
    end

  end

  describe 'run the job' do
    context 'normal and success' do
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', debug_verbose_count
    end
    context 'normal and failure' do
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', debug_verbose_count
    end
    context 'normal success with debug_verbose' do
      debug_verbose_count = 1
      it_behaves_like 'it performs the job', debug_verbose_count
    end
  end

end
