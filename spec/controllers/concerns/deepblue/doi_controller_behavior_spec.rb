require 'rails_helper'

class MockDeepblueDoiControllerBehavior

  include Deepblue::DoiControllerBehavior

end

RSpec.describe Deepblue::DoiControllerBehavior do

  subject { MockDeepblueDoiControllerBehavior.new }

  it { expect( Deepblue::DoiControllerBehavior::DOI_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE ).to eq false }

  it { expect( Deepblue::DoiControllerBehavior.doi_controller_behavior_debug_verbose ).to eq false }

  it { expect( subject.doi_minting_enabled? ).to eq ::Deepblue::DoiBehavior::DOI_MINTING_ENABLED }

end
