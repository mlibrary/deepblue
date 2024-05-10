# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.application_controller_debug_verbose ).to eq debug_verbose }
  end

  describe 'constants' do
    it { expect( described_class::ANTISPAM_TIMESTAMP ).to eq 'antispam_timestamp' }
  end

  subject { ApplicationController.new }

  it { expect( subject.single_use_link_request? ).to eq false }

end
