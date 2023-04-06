# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::TicketHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug variables' do
    it { expect( described_class.ticket_helper_debug_verbose ).to eq false }
  end

end
