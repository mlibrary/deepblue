# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestAppendScriptMonitorJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.ingest_append_script_monitor_job_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables' do
    it { expect( described_class.ingest_append_script_monitor_job_verbose ).to eq false }
    it { expect( described_class.ingest_append_script_max_restarts_base ).to eq 4 }
    it { expect( described_class.ingest_append_script_monitor_wait_duration ).to eq 10 }
  end

end
