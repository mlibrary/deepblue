# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Renderers::DoiAttributeRenderer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.doi_attribute_renderer_debug_verbose ).to eq debug_verbose }
  end

  describe '#attribute_value_to_html' do
    let(:field) { 'this is ignored' }
    let(:values) { ['ignored'] }
    let(:options) { { ignored: true } }
    let(:pending) { ::Deepblue::DoiBehavior.doi_pending }
    let(:https) { "http://some.address" }
    let(:doi_noid) { 'doi:the_doi_noid' }
    let(:doi) { "doi:#{doi_noid}" }
    let(:doi_expected) { "https://doi.org/#{doi_noid}"}

    it 'renders pending' do
      expect(described_class.new(field,values,options).attribute_value_to_html(pending)).to eq pending
    end

    it 'renders with leading https' do
      expect(described_class.new(field,values,options).attribute_value_to_html(https)).to eq https
    end

    it 'renders doi' do
      expect(described_class.new(field,values,options).attribute_value_to_html(doi)).to eq doi_expected
    end

    it 'renders anything else as nil' do
      expect(described_class.new(field,values,options).attribute_value_to_html("random stuff")).to eq "random stuff"
    end

  end

end
