# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Orcid::Strategy::SyncAll do
  let(:sync_preference) { "sync_all" }
  let(:strategy) { described_class.new(work, orcid_identity) }
  let(:user) { factory_bot_create_user(:user) }
  let!(:orcid_identity) { create(:orcid_identity, work_sync_preference: sync_preference, user: user) }
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
  let(:orcid_id) { user.orcid_identity.orcid_id }
  let(:service_class) { Hyrax::Orcid::Work::PublisherService }
  let(:service) { instance_double(service_class, publish: nil) }

  before do
    allow(service_class).to receive(:new).and_return(service)
  end

  describe "#perform" do
    context "when the depositor is the primary referenced user" do
      it "calls the perform method" do
        strategy.send(:perform)

        expect(service).to have_received(:publish).with(no_args)
      end
    end

    context "when the referenced user is not the depositor" do
      let(:strategy) { described_class.new(work, orcid_identity2) }
      let(:user2) { factory_bot_create_user(:user) }
      let!(:orcid_identity2) { create(:orcid_identity, work_sync_preference: sync_preference, user: user2) }
      let(:orcid_id) { user2.orcid_identity.orcid_id }

      it "creates a job" do
        strategy.send(:perform)

        expect(service).to have_received(:publish).with(no_args)
      end
    end
  end
end
