# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::IrusHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module variables' do
    it { expect( described_class.irus_log_echo_to_rails_logger ).to eq true }
  end

  context 'logging' do
    let(:msg) { 'Here I am with a brain the size of a planet and they ask me to pick up a piece of paper. Call that job satisfaction? I don\'t.'}

    before do
      expect(::Deepblue::IRUS_LOGGER).to receive(:info).with msg
    end

    it '#log_raw' do
      subject.log_raw msg
    end

  end

end
