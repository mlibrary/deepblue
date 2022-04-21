require 'rails_helper'

class MockPresentsAttributes
  include Hyrax::PresentsAttributes

  attr_accessor :test_attribute, :test_attribute_array

end

RSpec.describe Hyrax::PresentsAttributes do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.presents_attribute_debug_verbose ).to eq debug_verbose }
  end

  describe '#attribute_to_html' do
    let(:field) { :test_attribute }
    let(:options) { { ignored: true } }
    let(:mock) { MockPresentsAttributes.new }
    let(:test_attribute) { 'test_attribute' }
    let(:test_attribute_array) { ['Test 1', 'Test 2'] }
    let(:expected_render) { "<tr><th>Test attribute</th>\n<td><ul class='tabular'><li class=\"attribute attribute-test_attribute\">test_attribute</li></ul></td></tr>" }
    let(:expected_array_render) { "<tr><th>Test attribute</th>\n<td><ul class='tabular'><li class=\"attribute attribute-test_attribute\">test_attribute</li></ul></td></tr>" }

    before do
      mock.test_attribute = test_attribute
      mock.test_attribute_array = test_attribute_array
    end

    it 'renders a single attribute' do
      expect(mock.attribute_to_html(:test_attribute,options)).to eq expected_render
    end

    it 'renders an array of attributes' do
      expect(mock.attribute_to_html(:test_attribute,options)).to eq expected_array_render
    end

  end


end
