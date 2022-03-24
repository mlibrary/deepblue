# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::ProvenanceLogService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.provenance_log_service_debug_verbose ).to eq debug_verbose }
  end

  it { expect( described_class.provenance_log_name ).to eq Rails.configuration.provenance_log_name }
  it { expect( described_class.provenance_log_path ).to eq Rails.configuration.provenance_log_path }

end
