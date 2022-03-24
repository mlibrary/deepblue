require 'rails_helper'

RSpec.describe ProvenanceLogController do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.provenance_log_controller_debug_verbose ).to eq debug_verbose }
  end

  describe 'class variables' do
    it { expect( described_class.presenter_class ).to eq ProvenanceLogPresenter }
  end

end
