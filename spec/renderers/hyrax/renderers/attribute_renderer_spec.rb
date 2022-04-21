require 'rails_helper'

RSpec.describe Hyrax::Renderers::AttributeRenderer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.attribute_renderer_debug_verbose ).to eq debug_verbose }
  end

end
