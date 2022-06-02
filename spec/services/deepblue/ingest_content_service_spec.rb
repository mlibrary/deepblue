# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::IngestContentService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.ingest_content_service_debug_verbose ).to eq debug_verbose }
  end

end
