require 'rails_helper'

class MockSingleUseLinkControllerBehavior

  include Deepblue::SingleUseLinkControllerBehavior

end

RSpec.describe Deepblue::SingleUseLinkControllerBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.single_use_link_controller_behavior_debug_verbose ).to eq debug_verbose
    end
  end

  subject { MockSingleUseLinkControllerBehavior.new }

  it { expect( subject.singleton_class.include? Deepblue::SingleUseLinkControllerBehavior ).to eq true }

end
