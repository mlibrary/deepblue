# frozen_string_literal: true
# hyrax-orcid

require 'rails_helper'

RSpec.describe Hyrax::Orcid::IdentityStrategyDelegator do
  let(:service) { described_class.new(work) }
  let(:user) { create(:user) }
  let!(:orcid_identity) { create(:orcid_identity, work_sync_preference: work_sync_preference, user: user) }
  let(:work) { create(:work, user: user, **work_attributes) }

  let(:work_attributes) do
    {
      "title" => ["Moomin"],
      "creator" => [
        [{
          "creator_name" => "John Smith",
          "creator_orcid" => orcid_id
        }].to_json
      ]
    }
  end
  let(:orcid_id) do
    orcid_identity # Ensure the association has been created

    user.orcid_identity.orcid_id
  end
  let(:work_sync_preference) { "sync_all" }

  before do
    allow(Flipflop).to receive(:enabled?).and_call_original
    allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(true)
    allow(Flipflop).to receive(:hyrax_orcid?).and_return true
  end

  describe ".new" do
    context "when arguments are used" do
      it "doesn't raise" do
        expect { described_class.new(work) }.not_to raise_error
      end
    end

    context "when invalid type is used" do
      let(:work) { "foo" }

      it "raises" do
        expect { described_class.new(work) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#perform" do
    let(:headers) do
      {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Authorization" => "Bearer #{orcid_identity.access_token}",
        "Content-Type" => "application/vnd.orcid+xml",
        "User-Agent" => "Faraday v0.17.4"
      }
    end

    before do
      allow(service).to receive(:perform_user_strategy).and_call_original
      stub_request(:post, "https://api.sandbox.orcid.org/v2.1/#{orcid_id}/work")
        .with(body: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<work:work xmlns:common=\"http://www.orcid.org/ns/common\" xmlns:work=\"http://www.orcid.org/ns/work\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.orcid.org/ns/work /work-2.1.xsd \">\n  <work:title>\n    <common:title>Moomin</common:title>\n  </work:title>\n  <work:short-description/>\n  <work:type>other</work:type>\n  <common:external-ids>\n    <common:external-id>\n      <common:external-id-type>other-id</common:external-id-type>\n      <common:external-id-value>#{work.id}</common:external-id-value>\n      <common:external-id-relationship>self</common:external-id-relationship>\n    </common:external-id>\n  </common:external-ids>\n  <work:contributors>\n    <work:contributor>\n      <common:contributor-orcid>\n        <common:uri>https://orcid.org/#{orcid_id}</common:uri>\n        <common:path>#{orcid_id}</common:path>\n        <common:host>orcid.org</common:host>\n      </common:contributor-orcid>\n      <work:credit-name>John Smith</work:credit-name>\n      <work:contributor-attributes>\n        <work:contributor-sequence>first</work:contributor-sequence>\n        <work:contributor-role>author</work:contributor-role>\n      </work:contributor-attributes>\n    </work:contributor>\n  </work:contributors>\n</work:work>\n", headers: headers)
        .to_return(status: 200, body: "", headers: {})
    end

    context "when the feature is enabled" do
      it "calls the delegated sync class" do
        service.perform

        expect(service).to have_received(:perform_user_strategy).with(orcid_id)
      end
    end

    context "when the feature is disabled" do
      before do
        allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(false)
        allow(Flipflop).to receive(:hyrax_orcid?).and_return false
      end

      it "returns nil" do
        expect(service).not_to have_received(:perform_user_strategy).with(orcid_id)
      end
    end
  end

  describe "#perform_user_strategy" do
    before do
      allow(Hyrax::Orcid::PerformIdentityStrategyJob).to receive(:perform_now).with(work, orcid_identity)
      allow(::Hyrax::OrcidIntegrationService).to receive(:active_job_type).and_return :perform_now
      service.send(:perform_user_strategy, orcid_id)
    end

    it "calls the perform method on the sync class" do
      expect(Hyrax::Orcid::PerformIdentityStrategyJob).to have_received(:perform_now).with(work, orcid_identity)
    end
  end
end
