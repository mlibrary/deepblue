# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestAppendScriptJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.ingest_append_script_job_debug_verbose ).to eq debug_verbose }
  end

  it "is TODO" do
    skip "the test code goes here"
  end

end