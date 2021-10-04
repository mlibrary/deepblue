require 'rails_helper'

RSpec.describe Deepblue::SearchResultJsonPresenter do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.search_result_json_presenter_debug_verbose ).to eq( debug_verbose )
    end
  end

  it "is TODO" do
    skip "the test code goes here"
  end

end
