require 'rails_helper'

RSpec.describe IngestDashboardController do
  subject { described_class.new }

  it { expect( described_class.ingest_dashboard_controller_debug_verbose ).to eq false }

end
