require 'rails_helper'

RSpec.describe Deepblue::WorkflowEventBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.workflow_event_behavior_debug_verbose ).to eq debug_verbose }
  end

end
