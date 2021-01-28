# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchedulerDashboardController do
  subject { described_class.new }

  it { expect( SchedulerDashboardController.scheduler_dashboard_controller_debug_verbose ).to eq false }

end
