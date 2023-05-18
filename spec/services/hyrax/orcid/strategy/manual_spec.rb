# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Orcid::Strategy::Manual do
  let(:sync_preference) { "manual" }
  let(:service) { described_class.new(work, orcid_identity) }
  let(:user) { create(:user) }
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

  describe "#perform" do
    context "when the depositor is the primary referenced user" do
      it "does nothing" do
        expect(service.perform).to be_nil
      end
    end

    context "when the referenced user is not the depositor" do
      let(:service) { described_class.new(work, orcid_identity2) }
      let(:user2) { create(:user) }
      let!(:orcid_identity2) { create(:orcid_identity, work_sync_preference: sync_preference, user: user2) }
      let(:orcid_id) { user2.orcid_identity.orcid_id }

      it "does nothing" do
        expect(service.perform).to be_nil
      end
    end
  end
end
