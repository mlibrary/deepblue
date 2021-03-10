# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestScriptJob, skip: false do

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.ingest_script_job_debug_verbose ).to eq false
    end
  end

  context 'with valid arguments and scheduler running' do
    let(:ingest_mode)    { "append" }
    let(:ingester)       { "ingester@umich.edu" }
    let(:options)        { {} }
    let(:path_to_script) { '/some/path/to/script' }
    let(:job)            { described_class.send( :job_or_instantiate,
                                                 path_to_script: path_to_script,
                                                 ingest_mode: ingest_mode,
                                                 ingester: ingester,
                                                 **options ) }
    let(:hostname)  { DeepBlueDocs::Application.config.hostname }

    before do
      expect( described_class.ingest_script_job_debug_verbose ).to eq false
      expect( ::Deepblue::IngestContentService ).to receive( :call ).with( path_to_yaml_file: path_to_script,
                                                         ingester: ingester,
                                                         mode: ingest_mode,
                                                         options: options )
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
