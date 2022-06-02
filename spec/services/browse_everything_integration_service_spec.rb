# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BrowseEverythingIntegrationService do

  let(:debug_verbose) { true }

  describe 'module debug verbose variables' do
    it { expect( described_class.browse_everything_browser_debug_verbose ).to eq false }
    it { expect( described_class.browse_everything_controller_debug_verbose ).to eq true }
    it { expect( described_class.browse_everything_controller2_debug_verbose ).to eq false }
    it { expect( described_class.browse_everything_driver_authentication_factory_debug_verbose ).to eq true }
    it { expect( described_class.browse_everything_driver_base_debug_verbose ).to eq true }
    it { expect( described_class.browse_everything_driver_base2_debug_verbose ).to eq false }
    it { expect( described_class.browse_everything_driver_dropbox_debug_verbose ).to eq true }
    it { expect( described_class.browse_everything_driver_dropbox2_debug_verbose ).to eq false }
    it { expect( described_class.browse_everything_views_debug_verbose ).to eq true }
  end

end
