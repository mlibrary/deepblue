# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::InterpolationHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.interpolation_helper_debug_verbose ).to eq debug_verbose }
  end

  describe 'other module values' do
    it { expect( described_class.interpolation_pattern ).to eq /(?-mix:%%)|(?-mix:%\{([\w|]+)\})|(?-mix:%<(\w+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps]))/ }
  end

  describe '#new_interporlation_values' do
    let(:expected) {
      { contact_us_at: ::Deepblue::EmailHelper.contact_us_at,
      host_url: Rails.configuration.hostname,
      example_collection_id: "c1234567",
      example_data_set_id: "d1234567",
      example_file_set_id: "f1234567" }
    }

    it { expect(described_class.new_interporlation_values).to eq expected }

  end

  describe '#interpolate' do
    let(:target) { ["yes, %{user1}", ["maybe no, %{user2}", "no, %{user1}"]] }
    let(:values) { { user1: "bartuz", user2: "fantastix" } }
    let(:expected) { ["yes, bartuz", ["maybe no, fantastix", "no, bartuz"]] }

    it { expect(described_class.interpolate( target: target, values: values )).to eq expected }

  end

end
