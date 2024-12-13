# frozen_string_literal: true
# hyrax-orcid
# Skip: hyrax4

require 'rails_helper'

RSpec.describe "The Dashboard User Profile Page", type: :feature, js: true, clean: true, skip: Rails.configuration.hyrax4_spec_skip || ENV['CIRCLECI'].present? do

  include Devise::Test::IntegrationHelpers

  let(:user) { factory_bot_create_user(:admin) }
  let(:code) { "123456" }
  let(:orcid_id) { "0000-0003-0652-1234" }
  let(:access_token) { "292b3a63-1259-44bf-a0f8-11bf15134920" }

  before do
    WebMock.enable!

    allow_any_instance_of(Ability).to receive(:admin_set_with_deposit?).and_return(true)
    allow_any_instance_of(Ability).to receive(:can?).and_call_original
    allow_any_instance_of(Ability).to receive(:can?).with(:new, anything).and_return(true)

    allow(Flipflop).to receive(:enabled?).and_call_original
    allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(true)
    allow(Flipflop).to receive(:hyrax_orcid?).and_return true

    sign_in user
  end

  describe "when the feature is disabled", skip: true do
    before do
      allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(false)
      allow(Flipflop).to receive(:hyrax_orcid?).and_return false

      visit hyrax.dashboard_profile_path(user.to_param, locale: "en")
    end

    it "does not display the authorize link" do
      expect(page).not_to have_link("Connect to ORCID")
    end
  end

  describe "when the user has not linked their account", skip: true do
    before do
      visit hyrax.dashboard_profile_path(user.to_param, locale: "en")
    end

    it "displays the authorize link" do
      expect(page).to have_link("Connect to ORCID")
      expect(find_link("Connect to ORCID")[:href]).to include("https://sandbox.orcid.org/oauth/authorize")
    end
  end

  # TODO: fix
  describe "when the user is returning from the ORCID authorization endpoint", skip: true do
    let(:response_body) do
      {
        "access_token": access_token,
        "token_type": "bearer",
        "refresh_token": "55a45c88-59d7-4646-b30e-836b3dead62c",
        "expires_in": 631_138_518,
        "scope": "/read-limited /activities/update",
        "name": "Johnny Testing",
        "orcid": orcid_id
      }.to_json
    end

    before do
      stub_request(:post, "https://sandbox.orcid.org/oauth/token")
        .with(
          body: { "client_id": "", "client_secret": "", "code": code, "grant_type": "authorization_code" },
          headers: {
            "Accept": "application/json",
            "Accept-Encoding": "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "Faraday v0.17.4"
          }
        )
        .to_return(status: 200, body: response_body, headers: {})

      visit Rails.application.routes.url_helpers.new_orcid_identity_path(code: code)
    end

    it "redirects back to the users profile" do
      expect(page).to have_current_path(hyrax.dashboard_profile_path(user.to_param))
    end

    it "shows the correct information" do
      expect(page).to have_content(orcid_id)
      expect(page).to have_content(user.name)
      expect(page).not_to have_link("Connect to ORCID")
    end

    it "creates the orcid identity for the current user" do
      expect(user.orcid_identity).to be_present
      expect(user.orcid_identity.access_token).to eq(access_token)
      expect(user.orcid_identity.orcid_id).to eq(orcid_id)
    end
  end

  # TODO: fix this to remove skip
  describe "when the user has linked their account", skip: true do
    let(:user) { factory_bot_create_user(:user) }
    let(:orcid_identity) { create(:orcid_identity, work_sync_preference: sync_preference, user: user) }
    let(:sync_preference) { "sync_all" }
    let(:work) { create(:work, :public, **work_attributes) }
    let(:work_attributes) do
      {
        "creator" => [
          [{
            "creator_name" => user.name,
            "creator_orcid" => user.orcid_identity.orcid_id
          }].to_json
        ]
      }
    end
    let(:orcid_work) {}

    before do
      # I am not sure let! does what i need
      orcid_identity && work && orcid_work

      visit hyrax.dashboard_profile_path(user.to_param, locale: "en")
    end

    it "displays the options panel" do
      expect(page).to have_content(orcid_identity.orcid_id)
      expect(page).to have_content(user.name)
      expect(page).not_to have_link("Connect to ORCID")
    end

    context "when the user has referenced works" do
      it "displays the work with sync unchecked" do
        expect(page).to have_selector("tr.referenced-work", count: 1)
        expect(page).to have_unchecked_field("referenced-work-#{work.id}")
      end
    end

    context "when the user has a synced referenced work" do
      let(:orcid_work) { orcid_identity.orcid_works.create(work_uuid: work.id, put_code: 123_456) }

      it "displays the work with sync checked" do
        expect(page).to have_selector("tr.referenced-work", count: 1)
        expect(page).to have_checked_field("referenced-work-#{work.id}")
      end
    end

    # TODO: fix
    context "when the work is private", skip: true do
      let(:work) { create(:work, :private, **work_attributes) }

      it "does not display the work" do
        expect(page).to have_content(I18n.t("hyrax.orcid.preferences.works.nothing_found"))
        expect(page).not_to have_selector("tr.referenced-work", count: 1)
        expect(page).not_to have_field("referenced-work-#{work.id}")
      end
    end
  end
end
