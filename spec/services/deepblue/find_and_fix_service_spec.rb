# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::FindAndFixService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.find_and_fix_service_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables have the correct values' do
    it { expect( described_class.find_and_fix_default_verbose ).to eq true }
    it { expect( described_class.find_and_fix_file_sets_lost_and_found_work_title ).to eq 'DBD_Find_and_Fix_FileSets_Lost_and_Found' }
  end

end
