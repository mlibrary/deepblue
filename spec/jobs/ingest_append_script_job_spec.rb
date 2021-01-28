# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestAppendScriptJob, skip: false do

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.ingest_append_script_job_debug_verbose ).to eq( false )
    end
  end

  context 'with valid arguments and scheduler running' do
    let(:ingester)    { "ingester@umich.edu" }
    let(:options)   { {} }
    let(:path_to_script) { '/some/path/to/script' }
    let(:job)       { described_class.send( :job_or_instantiate,
                                            path_to_script: path_to_script,
                                            ingester: ingester,
                                            **options ) }
    let(:hostname)  { DeepBlueDocs::Application.config.hostname }

    before do
      expect( described_class.ingest_append_script_job_debug_verbose ).to eq false
      expect( ::Deepblue::IngestContentService ).to receive( :call ).with( path_to_yaml_file: path_to_script,
                                                         ingester: ingester,
                                                         mode: 'append',
                                                         options: options )
    end

    it 'calls ingest service' do
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
    end

  end

end
