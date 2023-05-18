# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Hyrax::OrcidIntegrationService do

  describe 'module debug verbose variables' do
    let(:debug_verbose) { false }
    it { expect( described_class.hyrax_orcid_debug_verbose ).to eq( debug_verbose ) }
    it { expect( described_class.hyrax_orcid_actors_debug_verbose ).to              eq( true ) }
    it { expect( described_class.hyrax_orcid_integration_service_debug_verbose ).to eq( true ) }
    it { expect( described_class.hyrax_orcid_jobs_debug_verbose ).to                eq( true ) }
    it { expect( described_class.hyrax_orcid_publisher_service_debug_verbose ).to   eq( true ) }
    it { expect( described_class.hyrax_orcid_strategy_debug_verbose ).to            eq( true ) }
    it { expect( described_class.orcid_user_behavior_debug_verbose ).to             eq( true ) }
  end

  describe 'other module values' do
    it { expect( described_class.active_job_type ).to eq( :perform_later ) }
    it { expect( described_class.environment ).to     eq( :sandbox ) }
  end

end
