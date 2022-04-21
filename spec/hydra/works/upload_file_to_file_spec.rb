require 'rails_helper'

RSpec.describe Hydra::Works::UploadFileToFileSet, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.upload_file_to_file_set_debug_verbose ).to eq debug_verbose }
  end

end
