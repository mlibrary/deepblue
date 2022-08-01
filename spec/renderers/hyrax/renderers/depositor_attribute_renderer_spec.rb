# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Renderers::DepositorAttributeRenderer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.depositor_attribute_renderer_debug_verbose ).to eq debug_verbose }
  end

  let(:field) { :creator }
  let(:one_creator) { ['Savage, Clarke'] }
  let(:six_creators) { ['Savage, Clarke', 'Brookes, Ham', 'Littlejohn, Johnny', 'Mayfair, Monk', 'Renwick, Renny', 'Roberts, Long Tom'] }
  let(:renderer) { described_class.new(field, ['Bob', 'Jessica']) }

  describe '#attribute_value_to_html' do
    let(:field) { 'this is ignored' }
    let(:options) { { ignored: true } }
    let(:values) { ['ignored'] }

    let(:email) { 'somebody@somewhere.com' }
    let(:tombstoned) { "TOMBSTONE-#{email}" }

    it 'renders an email address' do
      expect(described_class.new(field,values,options).attribute_value_to_html(email)).to eq email
    end

    it 'renders removes tombstone' do
      expect(described_class.new(field,values,options).attribute_value_to_html(tombstoned)).to eq email
    end

  end

end
