# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Hyrax::AnonymousLinkService do

  let(:enabled) { true }

  describe 'enabled' do
    it "resolves it" do
      expect( described_class.enable_anonymous_links ).to eq( enabled )
    end
  end

  describe 'module debug verbose variables' do
    let(:debug_verbose) { false }
    it "they have the right values" do
      expect( described_class.anonymous_link_controller_behavior_debug_verbose ).to eq( debug_verbose )
      expect( described_class.anonymous_link_service_debug_verbose ).to eq( debug_verbose )
      expect( described_class.anonymous_links_controller_debug_verbose ).to eq( debug_verbose )
      expect( described_class.anonymous_links_viewer_controller_debug_verbose ).to eq( debug_verbose )
    end
  end

  describe 'other module values' do
    it "resolves them" do
      expect( described_class.anonymous_link_show_delete_button ).to eq( false )
      expect( described_class.anonymous_link_destroy_if_published ).to eq( true )
      expect( described_class.anonymous_link_destroy_if_tombstoned ).to eq( true )
    end
  end

end
