require 'rails_helper'


class MockDeepblueCollectionsControllerBehavior < Hyrax::DeepblueController

  include Deepblue::CollectionsControllerBehavior

end

RSpec.describe Deepblue::CollectionsControllerBehavior do

  subject { MockDeepblueCollectionsControllerBehavior.new }

  it { expect( subject.singleton_class.include? Deepblue::ControllerWorkflowEventBehavior ).to eq true }

end
