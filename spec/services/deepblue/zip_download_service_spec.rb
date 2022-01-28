# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::ZipDownloadService do

  describe 'module debug verbose variables' do
    it { expect( described_class.zip_download_service_debug_verbose             ).to eq false }
    it { expect( described_class.zip_download_controller_behavior_debug_verbose ).to eq false }
    it { expect( described_class.zip_download_presenter_behavior_debug_verbose  ).to eq false }
  end

  describe 'other module values' do
    it { expect( described_class.zip_download_enabled                              ).to eq true         }
    it { expect( described_class.zip_download_max_total_file_size_to_download      ).to eq 10.gigabytes }
    it { expect( described_class.zip_download_min_total_file_size_to_download_warn ).to eq 1.gigabyte   }
  end

end
