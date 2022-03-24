# frozen_string_literal: true

require 'rails_helper'

class VirusScanServiceMock
  include ::Deepblue::VirusScanService
end

RSpec.describe ::Deepblue::VirusScanService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.virus_scan_service_debug_verbose ).to eq debug_verbose }
  end

  it { expect( described_class::VIRUS_SCAN_ERROR ).to eq 'scan error' }
  it { expect( described_class::VIRUS_SCAN_NOT_VIRUS ).to eq 'not virus' }
  it { expect( described_class::VIRUS_SCAN_SKIPPED ).to eq 'scan skipped' }
  it { expect( described_class::VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE ).to eq 'scan skipped service unavailable' }
  it { expect( described_class::VIRUS_SCAN_SKIPPED_TOO_BIG ).to eq 'scan skipped too big' }
  it { expect( described_class::VIRUS_SCAN_UNKNOWN ).to eq 'scan unknown' }
  it { expect( described_class::VIRUS_SCAN_VIRUS ).to eq 'virus' }

end
