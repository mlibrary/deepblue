require 'rails_helper'

class MockDeepbluedocsWorksControllerBehavior < Hyrax::DeepblueController

  include Deepbluedocs::WorksControllerBehavior

end

RSpec.describe Deepbluedocs::WorksControllerBehavior do

  subject { MockDeepbluedocsWorksControllerBehavior.new }

  it { expect( subject.singleton_class.include? Deepblue::WorksControllerBehavior ).to eq true }

end
