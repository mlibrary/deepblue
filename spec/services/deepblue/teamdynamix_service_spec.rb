# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::TeamdynamixService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.teamdynamix_service_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables have the expected values' do
    it { expect( ::Deepblue::TeamdynamixService.check_admin_notes_for_existing_ticket ).to eq true }
  end

  describe 'module related variables have the expected values' do
    it { expect( ::Deepblue::TeamdynamixIntegrationService.teamdynamix_integration_service_debug_verbose ).to eq false }
  end

end
