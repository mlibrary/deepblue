# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Hyrax::SingleUseLinkService do

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.single_use_link_service_debug_verbose ).to eq( false )
    end
  end

  describe 'other module values' do
    it "resolves them" do
      expect( described_class.single_use_link_default_expiration_duration ).to eq( 365.days )
      expect( described_class.single_use_link_use_detailed_human_readable_time ).to eq( true )
    end
  end

end
