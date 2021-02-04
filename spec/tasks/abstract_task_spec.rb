# frozen_string_literal: true

require 'rails_helper'

require_relative "../../lib/tasks/abstract_task"

RSpec.describe ::Deepblue::AbstractTask, skip: false do

  describe 'constants', skip: true do
    it "resolves them" do
      expect( described_class::DEFAULT_TO_CONSOLE ).to eq true
      expect( described_class::DEFAULT_VERBOSE ).to eq false
    end
  end

end
