# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::FileContentHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.file_content_helper_debug_verbose ).to eq debug_verbose }
  end

  describe 'other module values' do
    it { expect( described_class.read_me_file_set_enabled ).to eq true }
    it { expect( described_class.read_me_file_set_auto_read_me_attach ).to eq true }
    it { expect( described_class.read_me_file_set_file_name_regexp ).to eq /read[_ ]?me/i }
    it { expect( described_class.read_me_file_set_view_max_size ).to eq 500.kilobytes }
    it { expect( described_class.read_me_file_set_view_mime_types ).to eq  ["text/plain", "text/markdown", "text/html"] }
    it { expect( described_class.read_me_file_set_ext_as_html ).to eq [ ".md" ] }
    it { expect( described_class.read_me_max_find_file_sets ).to eq 40 }
  end

end
