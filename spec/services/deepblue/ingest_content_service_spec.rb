# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::IngestContentService do

  describe 'constants' do
    it "resolves them" do
      expect( described_class.ingest_content_service_debug_verbose ).to eq true
    end
  end

end
