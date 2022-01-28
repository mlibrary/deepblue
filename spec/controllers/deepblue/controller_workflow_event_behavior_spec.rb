require 'rails_helper'

RSpec.describe Deepblue::ControllerWorkflowEventBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.controller_workflow_event_behavior_debug_verbose ).to eq debug_verbose
    end
  end

end
