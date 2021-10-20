# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ServerAfterInitializeService do

  describe 'module debug verbose variables' do
    let(:debug_verbose) { false }
    it { expect( described_class.server_after_initialize_service_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.server_after_initialize_service_work_view_content_debug_verbose ).to eq false }
  end

end
