require 'rails_helper'

class MockDeepblueWorksControllerBehavior < Hyrax::DeepblueController

  include Deepblue::WorksControllerBehavior

end

RSpec.describe Deepblue::WorksControllerBehavior do

  subject { MockDeepblueWorksControllerBehavior.new }

  it { expect( subject.singleton_class.include? Hyrax::WorksControllerBehavior ).to eq true }

end
