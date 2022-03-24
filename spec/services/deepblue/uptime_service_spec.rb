# frozen_string_literal: true

require 'rails_helper'

class UptimeServiceMock
  include ::Deepblue::UptimeService
end

RSpec.describe ::Deepblue::UptimeService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.uptime_service_debug_verbose ).to eq debug_verbose }
  end

end
