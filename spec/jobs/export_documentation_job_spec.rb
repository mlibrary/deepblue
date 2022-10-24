require 'rails_helper'

RSpec.describe ExportDocumentationJob do

  let(:debug_verbose)   {false}

  describe 'module debug verbose variables' do
    it { expect( described_class.export_documentation_job_debug_verbose ).to eq debug_verbose }
  end

  RSpec.shared_examples 'export_documentation performs the job' do |job_args, expected_args, debug_verbose_count|
    let(:dbg_verbose) { debug_verbose_count > 0 }
    let(:job)         { described_class.send(:job_or_instantiate, *job_args) }
    let(:service)     { ::Deepblue::YamlPopulateFromCollection.allocate }

    before do
      expect(job).to receive(:perform_now).with(no_args).and_call_original
      if 0 < debug_verbose_count
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
      else
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
      end
    end

    it 'it performs the job' do
      save_debug_verbose = described_class.export_documentation_job_debug_verbose
      described_class.export_documentation_job_debug_verbose = dbg_verbose
      expect(described_class.export_documentation_job_debug_verbose).to eq dbg_verbose
      allow(job).to receive(:hostname_allowed?).and_return true
      expect(::Deepblue::YamlPopulateFromCollection).to receive(:new) do |args|
        expect(args[:id]).to eq ::Deepblue::WorkViewContentService.content_documentation_collection_id
        expect(args[:options]).to eq expected_args[:options]
        expect(args[:msg_handler]).to_not eq nil
      end.and_return service
      expect(service).to receive(:run).with(no_args)
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      described_class.export_documentation_job_debug_verbose = save_debug_verbose
    end

  end

  describe 'run the job' do
    job_args = {}
    expected_args = { options: { "target_dir" => ::Deepblue::WorkViewContentService.export_documentation_path,
                                 "export_files" => true,
                                 "mode" => "build" } }
    context 'normal and success' do
      debug_verbose_count = 0
      it_behaves_like 'export_documentation performs the job', job_args, expected_args, debug_verbose_count
    end
    context 'normal success with debug_verbose' do
      debug_verbose_count = 1
      it_behaves_like 'export_documentation performs the job', job_args, expected_args, debug_verbose_count
    end
  end

  # describe 'run the job with non-default args' do
  #   job_args = { start_day_span: 45, increment_day_span: 10, max_day_spans: 5, verbose: true }
  #   expected_args = { start_day_span: 45, increment_day_span: 10, max_day_spans: 5, verbose: true }
  #   context 'normal and success' do
  #     debug_verbose_count = 0
  #     it_behaves_like 'export_documentation performs the job', job_args, expected_args, debug_verbose_count
  #   end
  #   context 'normal and failure' do
  #     debug_verbose_count = 0
  #     it_behaves_like 'export_documentation performs the job', job_args, expected_args, debug_verbose_count
  #   end
  #   context 'normal success with debug_verbose' do
  #     debug_verbose_count = 1
  #     it_behaves_like 'export_documentation performs the job', job_args, expected_args, debug_verbose_count
  #   end
  # end

end
