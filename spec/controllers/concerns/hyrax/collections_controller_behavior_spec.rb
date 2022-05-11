require 'rails_helper'

RSpec.describe Hyrax::CollectionsControllerBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.hyrax_collections_controller_behavior_debug_verbose ).to eq( debug_verbose ) }
  end

end
