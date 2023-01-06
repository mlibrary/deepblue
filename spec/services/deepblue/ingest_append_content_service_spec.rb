# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::IngestAppendContentService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.ingest_append_content_service_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables' do
    it { expect( described_class.add_job_json_to_ingest_script ).to eq false }
  end

end
