# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Hyrax::AnonymousLinkService do

  let(:enabled) { true }

  describe 'enabled' do
    it { expect( described_class.enable_anonymous_links ).to eq( enabled ) }
  end

  describe 'module debug verbose variables' do
    let(:debug_verbose) { false }
    it { expect( described_class.anonymous_link_controller_behavior_debug_verbose ).to eq( debug_verbose ) }
    it { expect( described_class.anonymous_link_service_debug_verbose ).to eq( debug_verbose ) }
    it { expect( described_class.anonymous_links_controller_debug_verbose ).to eq( debug_verbose ) }
    it { expect( described_class.anonymous_links_viewer_controller_debug_verbose ).to eq( debug_verbose ) }
  end

  describe 'other module values' do
    it { expect( described_class.anonymous_link_show_delete_button ).to eq( false ) }
    it { expect( described_class.anonymous_link_destroy_if_published ).to eq( true ) }
    it { expect( described_class.anonymous_link_destroy_if_tombstoned ).to eq( true ) }
  end

end
