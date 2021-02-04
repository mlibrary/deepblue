# frozen_string_literal: true

require 'rails_helper'

class MockJobHelper
  include JobHelper
end

RSpec.describe JobHelper, type: :helper do

  describe '#job_options_keys_found' do
    subject { MockJobHelper.new }

    it "job_options_keys_found default" do
      expect( subject.job_options_keys_found ).to eq []
    end

  end
  describe '#job_options_value', skip: true do
    subject { MockJobHelper.new }

    it "job_options_value" do
      expect( subject.job_options_keys_found ).to eq []
    end

  end

end
