# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Orcid::Strategy::SyncNotify do
  let(:sync_preference) { "sync_notify" }
  let(:strategy) { described_class.new(work, orcid_identity) }
  let(:user) { create(:user) }
  let!(:orcid_identity) { create(:orcid_identity, work_sync_preference: sync_preference, user: user) }
  let(:work) { create(:work, :public, user: user, **work_attributes) }
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

  describe "#perform" do
    context "when the depositor is the primary referenced user" do
      before do
        allow(strategy).to receive(:notify)
        allow(strategy).to receive(:publish_work)
      end

      it "calls publish_work" do
        strategy.perform

        expect(strategy).to have_received(:publish_work)
      end
    end

    context "when the referenced user is not the depositor" do
      let(:strategy) { described_class.new(work, orcid_identity2) }
      let(:user2) { create(:user) }
      let!(:orcid_identity2) { create(:orcid_identity, work_sync_preference: sync_preference, user: user2) }
      let(:orcid_id) { user2.orcid_identity.orcid_id }

      # NOTE: The strategies before block cannot be shared or this spec fails and I dont understand why
      before do
        allow(strategy).to receive(:notify)
        allow(strategy).to receive(:publish_work)
      end

      it "calls notify" do
        strategy.perform

        expect(strategy).to have_received(:notify)
      end
    end
  end

  describe "#publish_work" do
    let(:service_class) { Hyrax::Orcid::Work::PublisherService }
    let(:service) { instance_double(service_class, publish: nil) }

    before do
      allow(service_class).to receive(:new).and_return(service)
    end

    context "when the user has selected sync_all" do
      it "calls the perform method" do
        strategy.send(:publish_work)

        expect(service).to have_received(:publish).with(no_args)
      end
    end
  end

  describe "#primary_user?" do
    context "when the user depositing the work is referenced" do
      it "returns true" do
        expect(strategy.send(:primary_user?)).to be_truthy
      end
    end

    context "when the depositing user is not the user being referenced" do
      let(:strategy) { described_class.new(work, orcid_identity2) }
      let(:user2) { create(:user) }
      let!(:orcid_identity2) { create(:orcid_identity, work_sync_preference: sync_preference, user: user2) }
      let(:orcid_id) { user2.orcid_identity.orcid_id }

      it "returns false" do
        expect(strategy.send(:primary_user?)).to be_falsey
      end
    end
  end

  describe "#notify" do
    let(:strategy) { described_class.new(work, orcid_identity2) }
    let(:user2) { create(:user) }
    let!(:orcid_identity2) { create(:orcid_identity, work_sync_preference: sync_preference, user: user2) }
    let(:orcid_id) { user2.orcid_identity.orcid_id }

    it "increments the message count for the referenced user" do
      expect { strategy.send(:notify) }.to change { UserMailbox.new(user2).inbox.count }.by(1)
    end
  end
end
