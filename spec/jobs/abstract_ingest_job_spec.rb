require 'rails_helper'

RSpec.describe AbstractIngestJob do

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.abstract_ingest_job_debug_verbose ).to eq( false )
    end
  end

  it "is TODO" do
    skip "the test code goes here"
  end
end
