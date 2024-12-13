# frozen_string_literal: true
# hyrax-orcid

RSpec.describe Hyrax::Orcid::PublishWorkJob do
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
  let(:sync_preference) { "sync_all" }

  before do
    allow(Flipflop).to receive(:enabled?).and_call_original
    allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(true)
    allow(Flipflop).to receive(:hyrax_orcid?).and_return true
  end

  describe ".perform_later" do
    before { ActiveJob::Base.queue_adapter = :test }

    it "enqueues the job" do
      expect { described_class.perform_later(work, orcid_identity) }
        .to enqueue_job(described_class)
        .on_queue(Hyrax.config.ingest_queue_name)
        .with(work, orcid_identity)
    end
  end

  describe ".perform" do
    let(:sync_class) { Hyrax::Orcid::Work::PublisherService }
    let(:sync_instance) { instance_double(sync_class, publish: nil) }

    before do
      allow(sync_class).to receive(:new).and_return(sync_instance)
    end

    it "calls the perform method" do
      described_class.perform_now(work, orcid_identity)

      expect(sync_instance).to have_received(:publish).with(no_args)
    end

    context "when the feature is disabled" do
      before do
        allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(false)
        allow(Flipflop).to receive(:hyrax_orcid?).and_return false
      end

      it "does not call the perform method" do
        described_class.perform_now(work, orcid_identity)

        expect(sync_instance).not_to have_received(:publish).with(no_args)
      end
    end
  end
end
