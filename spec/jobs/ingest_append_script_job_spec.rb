# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestAppendScriptJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.ingest_append_script_job_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables' do
    it { expect( described_class.ingest_append_script_job_verbose ).to eq false }
  end

end
