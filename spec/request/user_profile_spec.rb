# frozen_string_literal: true
# hyrax-orcid

require 'rails_helper'

# NOTE: We can't test that exceptions are raised from feature specs: https://github.com/rspec/rspec-rails/issues/1673
RSpec.describe "Links", type: :request do
  # include Hyrax::Orcid::Engine.routes.url_helpers

  # let(:user) { create(:user) }
  # let(:orcid_identity) { create(:orcid_identity, work_sync_preference: sync_preference, user: user) }
  # let(:sync_preference) { "sync_all" }
  # let(:url) { Rails.application.routes.url_helpers.users_orcid_profile_path(user.orcid_identity.orcid_id) }

  let(:user) { create(:user, :with_orcid_identity) }
  let(:orcid_identity) { user.orcid_identity }
  let(:sync_preference) { "sync_all" }
  let(:url) { Rails.application.routes.url_helpers.users_orcid_profile_path(user.orcid_identity.orcid_id) }

  before do
    WebMock.enable!
    orcid_identity
    allow(Flipflop).to receive(:enabled?).and_call_original
  end

  describe "when the feature is not disabled" do
    before do
      allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(true)
    end

    it "raises an error" do
      get url

      expect(response).to have_http_status(:ok)
    end
  end

  describe "when the feature is disabled" do
    before do
      allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(false)
    end

    it "raises an error" do
      expect { get url }.to raise_error(ActionController::RoutingError)
    end
  end
end
