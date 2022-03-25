
RSpec.describe ::Deepblue::CacheService do

  it { expect( described_class.cache_available? ).to eq false }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.deepblue_cache_service_debug_verbose ).to eq debug_verbose }
  end

end
