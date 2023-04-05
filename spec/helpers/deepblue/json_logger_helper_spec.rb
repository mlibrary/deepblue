# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::JsonLoggerHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.json_logging_helper_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.json_logging_helper_load_debug_verbose ).to eq false }
  end

  it "is TODO" do
    skip "the test code goes here"
  end

end
