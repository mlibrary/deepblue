require 'rails_helper'

class MockAnonymousLinkControllerBehavior

  include Deepblue::AnonymousLinkControllerBehavior

end

RSpec.describe Deepblue::AnonymousLinkControllerBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.anonymous_link_controller_behavior_debug_verbose ).to eq debug_verbose
    end
  end

  subject { MockAnonymousLinkControllerBehavior.new }

  it { expect( subject.singleton_class.include? Deepblue::AnonymousLinkControllerBehavior ).to eq true }

end
