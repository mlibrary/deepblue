require 'rails_helper'

class MockControllerWorkflowEventBehavior
  include ::Deepblue::ControllerWorkflowEventBehavior

end

RSpec.describe ::Deepblue::ControllerWorkflowEventBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.controller_workflow_event_behavior_debug_verbose ).to eq debug_verbose }
  end

end
