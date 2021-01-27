require 'rails_helper'

RSpec.describe ApplicationController do

  subject { ApplicationController.new }

  it { expect( subject.single_use_link_request? ).to eq false }

end
