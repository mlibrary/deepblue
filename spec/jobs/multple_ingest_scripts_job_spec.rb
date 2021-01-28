# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultipleIngestScriptsJob, skip: false do

  let(:ingest_append) { class_double( IngestAppendScriptJob ).as_stubbed_const(:transfer_nested_constants => true) }
  let(:ingester) { "ingester@umich.edu" }
  let(:options)  { {} }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.multiple_ingest_scripts_job_debug_verbose ).to eq( false )
    end
  end

  context 'with valid arguments and two paths' do
    let(:path1) { '/some/path/to/script1' }
    let(:path2) { '/some/path/to/script2' }
    let(:paths_to_scripts) { [ path1, path2 ] }
    let(:job)       { described_class.send( :job_or_instantiate,
                                            ingester: ingester,
                                            paths_to_scripts: paths_to_scripts,
                                            **options ) }

    before do
      expect( described_class.multiple_ingest_scripts_job_debug_verbose ).to eq false
      expect( job ).to receive( :init_paths_to_scripts ).with( paths_to_scripts ).and_call_original
      expect( job ).to receive( :validate_paths_to_scripts ).with( no_args ).and_return true
      expect( job ).to receive( :ingest_script_run ).with( path_to_script: path1 ).and_call_original
      expect( job ).to receive( :ingest_script_run ).with( path_to_script: path2 ).and_call_original
      expect( ingest_append ).to receive( :perform_now ).with( path_to_script: path1, ingester: ingester )
      expect( ingest_append ).to receive( :perform_now ).with( path_to_script: path2, ingester: ingester )
    end

    it 'it performs the job' do
      expect( job.hostname ).to eq ::DeepBlueDocs::Application.config.hostname
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
    end

  end

  describe '.hostname' do
    let(:job)       { described_class.send( :job_or_instantiate,
                                            ingester: ingester,
                                            paths_to_scripts: [],
                                            **options ) }
    it 'returns the application hostname' do
      expect( job.hostname ).to eq ::DeepBlueDocs::Application.config.hostname
    end
  end

end
