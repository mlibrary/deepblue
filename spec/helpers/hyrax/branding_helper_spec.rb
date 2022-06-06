# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Hyrax::BrandingHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.branding_helper_debug_verbose ).to eq debug_verbose }
  end

end
