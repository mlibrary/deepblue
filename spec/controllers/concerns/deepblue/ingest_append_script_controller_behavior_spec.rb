require 'rails_helper'

RSpec.describe Deepblue::IngestAppendScriptControllerBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.ingest_append_scripts_controller_behavior_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.ingest_append_scripts_controller_behavior_writer_debug_verbose ).to eq false }
  end

  describe 'module variables' do
    it { expect( described_class.ingest_append_script_max_appends ).to eq 20 }
    it { expect( described_class.ingest_append_script_max_restarts_base ).to eq 4 }
    it { expect( described_class.ingest_append_script_monitor_wait_duration ).to eq 2 }
  end

end
