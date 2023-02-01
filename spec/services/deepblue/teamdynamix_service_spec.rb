# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::TeamdynamixService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.teamdynamix_service_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.authentication_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.build_data_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.build_headers_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.get_ticket_body_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.esponse_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables have the expected values' do
    it { expect( described_class.check_admin_notes_for_existing_ticket ).to eq true }
    it { expect( described_class.include_attributes_in_update ).to eq false }
    it { expect( described_class.include_ibm_client_id ).to eq false }
    it { expect( described_class.build_access_token_parms ).to
                  eq '/um/oauth2/token?scope=tdxticket&grant_type=client_credentials' }
  end

  describe 'module related variables have the expected values' do
    it { expect( ::Deepblue::TeamdynamixIntegrationService.teamdynamix_integration_service_debug_verbose ).to eq false }
  end

end
