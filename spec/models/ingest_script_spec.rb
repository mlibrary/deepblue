# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestScript, type: :model do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.ingest_script_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.ingest_script_log_debug_verbose ).to eq false }
    it { expect( described_class.ingest_script_move_debug_verbose ).to eq false }
    it { expect( described_class.ingest_script_touch_debug_verbose ).to eq false }
  end

  # describe 'module values' do
  #
  # end

end