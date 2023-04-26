# frozen_string_literal: true
# hyrax-orcid

require 'rails_helper'

RSpec.describe Hyrax::Actors::Orcid::UnpublishWorkActor do
  subject(:actor) { described_class.new(next_actor) }
  let(:ability) { Ability.new(user) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, {}) }
  let(:next_actor) { Hyrax::Actors::Terminator.new }
  let(:user) { create(:user) }
  let!(:orcid_identity) { create(:orcid_identity, work_sync_preference: sync_preference, user: user) }
  let(:sync_preference) { "sync_all" }
  let(:model_class) { DataSet }
  let(:work) { model_class.create(work_attributes) }
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

  before do
    allow(Flipflop).to receive(:enabled?).and_call_original
    allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(true)
    allow(::Hyrax::OrcidIntegrationService).to receive(:active_job_type).and_return :perform_now

    ActiveJob::Base.queue_adapter = :test
  end

  describe "#destroy" do
    before do
      allow(Hyrax::Orcid::UnpublishWorkDelegatorJob).to receive(:perform_now).with(work)
      allow(Hyrax::Orcid::UnpublishWorkDelegator).to receive(:new).with(work)

      actor.destroy(env)
    end

    context "when hyrax_orcid is enabled" do
      it "performs a job" do
        expect(Hyrax::Orcid::UnpublishWorkDelegatorJob).to have_received(:perform_now).with(work)
      end
    end

    context "when hyrax_orcid is disabled" do
      before do
        allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(false)
      end

      it "does not perform a job" do
        expect(Hyrax::Orcid::UnpublishWorkDelegator).not_to have_received(:new).with(work)
      end
    end
  end
end
