require 'rails_helper'

RSpec.describe CleanBlacklightQueryCacheJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( ::Deepblue::JobTaskHelper.clean_blacklight_query_cache_job_debug_verbose ).to eq debug_verbose }
  end

  RSpec.shared_examples 'clean_blacklight_query_cache performs the job' do |job_args, expected_args, debug_verbose_count|
    let(:dbg_verbose) { debug_verbose_count > 0 }
    let(:job)         { described_class.send(:job_or_instantiate, *job_args) }

    before do
      expect(job).to receive(:perform_now).with(no_args).and_call_original
      if 0 < debug_verbose_count
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
      else
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
      end
    end

    it 'it performs the job' do
      save_debug_verbose = described_class.clean_blacklight_query_cache_job_debug_verbose
      described_class.clean_blacklight_query_cache_job_debug_verbose = dbg_verbose
      expect(described_class.clean_blacklight_query_cache_job_debug_verbose).to eq dbg_verbose
      allow(job).to receive(:hostname_allowed?).and_return true
      expect(::Deepblue::CleanUpHelper).to receive(:clean_blacklight_query_cache) do |args|
        expect(args[:increment_day_span]).to eq expected_args[:increment_day_span]
        expect(args[:start_day_span]).to eq expected_args[:start_day_span]
        expect(args[:max_day_spans]).to eq expected_args[:max_day_spans]
        expect(args[:msg_handler].is_a? ::Deepblue::MessageHandler).to eq true
        # expect(args[:msg_handler].msg_queue).to eq []
        expect(args[:msg_handler].to_console).to eq false
        expect(args[:msg_handler].verbose).to eq expected_args[:verbose]
        expect(args[:task]).to eq false
        expect(args[:verbose]).to eq expected_args[:verbose]
      end
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      described_class.clean_blacklight_query_cache_job_debug_verbose = save_debug_verbose
    end

  end

  describe 'run the job' do
    job_args = {}
    expected_args = { start_day_span: 30, increment_day_span: 15, max_day_spans: 0, verbose: false }
    context 'normal and success' do
      debug_verbose_count = 0
      it_behaves_like 'clean_blacklight_query_cache performs the job', job_args, expected_args, debug_verbose_count
    end
    context 'normal and failure' do
      debug_verbose_count = 0
      it_behaves_like 'clean_blacklight_query_cache performs the job', job_args, expected_args, debug_verbose_count
    end
    context 'normal success with debug_verbose' do
      debug_verbose_count = 1
      it_behaves_like 'clean_blacklight_query_cache performs the job', job_args, expected_args, debug_verbose_count
    end
  end

  describe 'run the job with non-default args' do
    job_args = { start_day_span: 45, increment_day_span: 10, max_day_spans: 5, verbose: true }
    expected_args = { start_day_span: 45, increment_day_span: 10, max_day_spans: 5, verbose: true }
    context 'normal and success' do
      debug_verbose_count = 0
      it_behaves_like 'clean_blacklight_query_cache performs the job', job_args, expected_args, debug_verbose_count
    end
    context 'normal and failure' do
      debug_verbose_count = 0
      it_behaves_like 'clean_blacklight_query_cache performs the job', job_args, expected_args, debug_verbose_count
    end
    context 'normal success with debug_verbose' do
      debug_verbose_count = 1
      it_behaves_like 'clean_blacklight_query_cache performs the job', job_args, expected_args, debug_verbose_count
    end
  end

end
