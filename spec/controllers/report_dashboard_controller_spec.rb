require 'rails_helper'

RSpec.describe ReportDashboardController do
  subject { described_class.new }

  it { expect( described_class.report_dashboard_controller_debug_verbose ).to eq true }

end
