# frozen_string_literal: true

require 'rails_helper'

require_relative "../../lib/tasks/new_content_service"

RSpec.describe ::Deepblue::NewContentService do

  describe 'constants' do
    it "resolves them" do
      expect( described_class.new_content_service_debug_verbose ).to eq false
      expect( described_class::DEFAULT_DATA_SET_ADMIN_SET_NAME ).to eq "DataSet Admin Set"
    end
  end

end
