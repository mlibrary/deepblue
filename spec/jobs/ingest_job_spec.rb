require 'rails_helper'

RSpec.describe IngestJob do

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.ingest_job_debug_spec ).to eq( true )
    end
  end

  it "is TODO" do
    skip "the test code goes here"
  end
end
