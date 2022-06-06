# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::ExportFilesHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.export_files_helper_debug_verbose ).to eq debug_verbose }
  end

end
