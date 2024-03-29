# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestScriptJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.ingest_script_job_debug_verbose ).to eq debug_verbose }
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared IngestScriptJob' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.ingest_script_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.ingest_script_job_debug_verbose = debug_verbose
      end
      context do

        context 'with valid arguments and scheduler running' do
          let(:ingest_mode)    { "append" }
          let(:ingester)       { "ingester@umich.edu" }
          let(:options)        { {} }
          let(:path_to_script) { '/some/path/to/script' }
          let(:job)            { described_class.send( :job_or_instantiate,
                                                       path_to_script: path_to_script,
                                                       ingest_mode: ingest_mode,
                                                       ingester: ingester,
                                                       # msg_handler: msg_handler,
                                                       **options ) }
          let(:hostname)  { Rails.configuration.hostname }

          before do
            expect( described_class.ingest_script_job_debug_verbose ).to eq dbg_verbose
            expect(::Deepblue::IngestContentService).to receive( :call ) do |args|
              expect(args[:path_to_yaml_file]).to eq path_to_script
              expect(args[:ingester]).to eq ingester
              expect(args[:mode]).to eq ingest_mode
              expect(args[:msg_handler].nil?).to eq false
              expect(args[:options]).to eq options
            end
          end

          it 'calls ingest service' do
            ActiveJob::Base.queue_adapter = :test
            job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
            expect( job.ingest_mode ).to eq ingest_mode
            expect( job.ingester ).to eq ingester
            expect( job.path_to_script ).to eq path_to_script
          end

        end
      end
    end
    it_behaves_like 'shared IngestScriptJob', false
    it_behaves_like 'shared IngestScriptJob', true
  end

end
