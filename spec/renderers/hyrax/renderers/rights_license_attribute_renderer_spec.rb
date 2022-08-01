# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Renderers::RightsLicenseAttributeRenderer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.rights_license_attribute_renderer_debug_verbose ).to eq debug_verbose }
  end

  describe '#attribute_value_to_html' do

    context '1' do
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

    context '2' do
      let(:field) { :rights_statement }
      let(:renderer) { described_class.new(field, ['http://rightsstatements.org/vocab/InC/1.0/']) }

      subject { Nokogiri::HTML(renderer.render) }

      let(:expected) { Nokogiri::HTML(tr_content) }

      let(:tr_content) do
        "<tr><th>Rights statement</th>\n" \
       "<td><ul class='tabular'>" \
       "<li class=\"attribute attribute-rights_statement\"><a href=\"http://rightsstatements.org/vocab/InC/1.0/\" target=\"_blank\">In Copyright</a></li>" \
       "</ul></td></tr>"
      end

      it { expect(renderer).not_to be_microdata(field) }
      it { expect(subject).to be_equivalent_to(expected) }

      context 'with off-authority term' do
        let(:renderer) { described_class.new(field, [value]) }
        let(:value)    { 'moomin' }

        it 'renders a value' do
          expect(subject.to_s).to include value
        end
      end
    end

  end

end
