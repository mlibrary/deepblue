# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::TeamdynamixHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.tdx_helper_debug_verbose ).to eq debug_verbose }
  end

  describe 'other module values' do
    it { expect( described_class::FIELD_NAME_CONTACT_INFO ).to eq "customfield_11315" }
    it { expect( described_class::FIELD_NAME_CREATOR      ).to eq "customfield_11304" }
    it { expect( described_class::FIELD_NAME_DEPOSIT_ID   ).to eq "customfield_11303" }
    it { expect( described_class::FIELD_NAME_DEPOSIT_URL  ).to eq "customfield_11305" }
    it { expect( described_class::FIELD_NAME_DESCRIPTION  ).to eq "description"       }
    it { expect( described_class::FIELD_NAME_DISCIPLINE   ).to eq "customfield_11309" }
    it { expect( described_class::FIELD_NAME_REPORTER     ).to eq "reporter"          }
    it { expect( described_class::FIELD_NAME_STATUS       ).to eq "customfield_12000" }
    it { expect( described_class::FIELD_NAME_SUMMARY      ).to eq "summary"           }
  end

end
