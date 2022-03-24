require 'rails_helper'

RSpec.describe WorkViewContentController do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.work_view_content_controller_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.static_content_helper_debug_verbose ).to eq false }
  end

  describe 'class variables' do
    it { expect( described_class.presenter_class ).to eq WorkViewContentPresenter }
  end

end
