require 'rails_helper'

RSpec.describe Hyrax::Renderers::RightsLicenseAttributeRenderer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.rights_license_attribute_renderer_debug_verbose ).to eq debug_verbose }
  end

  describe '#attribute_value_to_html' do
    let(:field) { 'this is ignored' }
    let(:values) { ['ignored'] }
    let(:options) { { ignored: true } }
    let(:valid_uri) { 'http://some.validaddress.com' }
    let(:label) { "label" }
    let(:valid_uri_html) { %(<a href=#{ERB::Util.h(valid_uri)} target="_blank">#{valid_uri}</a>) }
    let(:invalid_uri) { 'not a uri' }

    it 'renders valid uri' do
      expect(described_class.new(field,values,options).attribute_value_to_html(valid_uri)).to eq valid_uri_html
    end

    it 'renders invalid uri as original value' do
      expect(described_class.new(field,values,options).attribute_value_to_html(invalid_uri)).to eq invalid_uri
    end

  end

end
