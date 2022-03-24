require 'rails_helper'

RSpec.describe GuestUserMessageController do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  describe 'class variables' do
    it { expect( described_class.presenter_class ).to eq GuestUserMessagePresenter }
  end

end
