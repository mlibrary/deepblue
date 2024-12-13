require 'rails_helper'

RSpec.describe Hyrax::DeepblueController, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:user) { factory_bot_create_user(:user) }

  before { sign_in user }

  describe "#box_enabled?" do
    it { expect( controller.box_enabled? ).to eq false }
  end

end
