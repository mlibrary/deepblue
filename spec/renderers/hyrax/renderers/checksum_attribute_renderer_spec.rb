require 'rails_helper'

RSpec.describe Hyrax::Renderers::ChecksumAttributeRenderer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.checksum_attribute_renderer_debug_verbose ).to eq debug_verbose }
  end

  describe '#attribute_value_to_html' do
    let(:field) { 'this is ignored' }
    let(:values) { ['ignored'] }
    let(:algorithm) { 'ALGORITHM' }
    let(:options_with_algorithm) { { algorithm: algorithm } }
    let(:include_empty) { { include_empty: true } }
    let(:value) { 'TheChecksum' }
    let(:empty_values) { [] }

    it 'renders without algorithm when not passed' do
      expect(described_class.new(field,values,options_with_algorithm).attribute_value_to_html(value))
        .to eq "#{value}/#{algorithm}"
    end

    it 'renders with algorithm when passed' do
      expect(described_class.new(field,values).attribute_value_to_html(value)).to eq "#{value}"
    end

    it 'renders non-braking space when passed value is blank' do
      expect(described_class.new(field,empty_values,options_with_algorithm.merge(include_empty))
                            .attribute_value_to_html(value)).to eq "#{value}/#{algorithm}"
      expect(described_class.new(field,empty_values,include_empty).attribute_value_to_html(value)).to eq "#{value}"
    end

  end

end
